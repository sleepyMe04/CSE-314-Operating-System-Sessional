#include <stdio.h>
#include <pthread.h>
#include <semaphore.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/time.h>
#include <math.h>
#include <string.h>

#define MAX_SPIES 100
#define MAX_GROUPS 20
#define MAX_STAFF 2
#define TYPEWRITERS 4

int N, M;
double lambda_arrival, lambda_operation;
sem_t typewriters[TYPEWRITERS];
sem_t logbook;
pthread_mutex_t logbook_mutex;
pthread_mutex_t output_mutex;
int completed_operations = 0;
int readers_count = 0;
struct timeval start_time;

pthread_mutex_t group_mutex[MAX_GROUPS];
int group_counts[MAX_GROUPS] = {0};
sem_t group_semaphores[MAX_GROUPS];

int should_staff_continue = 1;
FILE *output_file;

// Thread-safe output function to file
void write_output(const char* output) {
    pthread_mutex_lock(&output_mutex);
    fprintf(output_file, "%s", output);
    fflush(output_file);
    pthread_mutex_unlock(&output_mutex);
}

// Poisson random number generator
int get_random_number(double lambda) {
    double L = exp(-lambda);
    int k = 0;
    double p = 1.0;
    do {
        k++;
        p *= ((double)rand() / RAND_MAX);
    } while (p > L);
    return k - 1;
}

// Time function
long long get_current_time() {
    struct timeval current_time;
    gettimeofday(&current_time, NULL);
    return (long long)(current_time.tv_sec - start_time.tv_sec) * 1000LL + 
           (long long)(current_time.tv_usec - start_time.tv_usec) / 1000LL;
}

void* spy_task(void* arg) {
    int spy_id = (int)(long)arg;
    int group_id = (spy_id - 1) / M;
    int is_leader = (spy_id % M == 0) || (spy_id == N);
    char buffer[256];

    // Random arrival delay
    usleep(get_random_number(lambda_arrival) * 1000);
    snprintf(buffer, sizeof(buffer), "Operative %d has arrived at typewriting station TS%d at time %lld\n", 
            spy_id, (spy_id - 1) % TYPEWRITERS + 1, get_current_time());
    write_output(buffer);

    int station_id = (spy_id - 1) % TYPEWRITERS;
    sem_wait(&typewriters[station_id]);
    
    int doc_time = lambda_arrival;
    snprintf(buffer, sizeof(buffer), "Operative %d has started document recreation at TS%d at time %lld\n",
            spy_id, station_id+1, get_current_time());
    write_output(buffer);
    usleep(doc_time * 1000);
    
    snprintf(buffer, sizeof(buffer), "Operative %d has completed document recreation at TS%d at time %lld\n",
            spy_id, station_id+1, get_current_time());
    write_output(buffer);
    sem_post(&typewriters[station_id]);

    // Group synchronization
    pthread_mutex_lock(&group_mutex[group_id]);
    group_counts[group_id]++;
    if (group_counts[group_id] == M) {
        snprintf(buffer, sizeof(buffer), "Unit %d has completed document recreation at time %lld\n",
                group_id + 1, get_current_time());
        write_output(buffer);
        for (int i = 0; i < M; i++) {
            sem_post(&group_semaphores[group_id]);
        }
    }
    pthread_mutex_unlock(&group_mutex[group_id]);
    
    sem_wait(&group_semaphores[group_id]);
    
    if (is_leader) {
        sem_wait(&logbook);
        int log_time = lambda_operation;
        snprintf(buffer, sizeof(buffer), "Leader %d has started logbook entry at time %lld\n",
                spy_id, get_current_time());
        write_output(buffer);
        usleep(log_time * 1000);
        
        completed_operations++;
        snprintf(buffer, sizeof(buffer), "Leader %d has completed logbook entry at time %lld\n",
                spy_id, get_current_time());
        write_output(buffer);
        sem_post(&logbook);
    }
    
    return NULL;
}

void* staff_task(void* arg) {
    int staff_id = (int)(long)arg;
    char buffer[256];
    
    snprintf(buffer, sizeof(buffer), "Intelligence Staff %d has started monitoring at time %lld\n",
            staff_id, get_current_time());
    write_output(buffer);
    
    while (should_staff_continue) {
        int delay = get_random_number((lambda_arrival + lambda_operation)/2);
        usleep(delay * 1000);
        
        pthread_mutex_lock(&logbook_mutex);
        readers_count++;
        if (readers_count == 1) {
            sem_wait(&logbook);
        }
        pthread_mutex_unlock(&logbook_mutex);
        
        snprintf(buffer, sizeof(buffer), "Intelligence Staff %d has started reading logbook at time %lld. Operations completed = %d\n",
                staff_id, get_current_time(), completed_operations);
        write_output(buffer);
        
        int read_time = get_random_number(lambda_operation/2);
        usleep(read_time * 1000);
        
        pthread_mutex_lock(&logbook_mutex);
        readers_count--;
        if (readers_count == 0) {
            sem_post(&logbook);
        }
        pthread_mutex_unlock(&logbook_mutex);
    }
    return NULL;
}

void init_semaphores() {
    for (int i = 0; i < TYPEWRITERS; i++) {
        sem_init(&typewriters[i], 0, 1);
    }
    sem_init(&logbook, 0, 1);
    pthread_mutex_init(&logbook_mutex, NULL);
    pthread_mutex_init(&output_mutex, NULL);
}

int main() {
    FILE *input_file = fopen("input.txt", "r");
    output_file = fopen("output.txt", "w");
    if (input_file == NULL || output_file == NULL) {
        perror("Error opening file");
        return 1;
    }
    
    if (fscanf(input_file, "%d %d %lf %lf", &N, &M, &lambda_arrival, &lambda_operation) != 4) {
        printf("Error reading input values from file\n");
        fclose(input_file);
        fclose(output_file);
        return 1;
    }
    fclose(input_file);
    
    gettimeofday(&start_time, NULL);
    srand(time(NULL));
    init_semaphores();
    
    int num_groups = N / M;
    for (int i = 0; i < num_groups; i++) {
        pthread_mutex_init(&group_mutex[i], NULL);
        sem_init(&group_semaphores[i], 0, 0);
    }
    
    pthread_t staff[MAX_STAFF];
    for (int i = 0; i < MAX_STAFF; i++) {
        pthread_create(&staff[i], NULL, staff_task, (void*)(long)(i+1));
    }

    pthread_t spies[N];
    for (int i = 0; i < N; i++) {
        pthread_create(&spies[i], NULL, spy_task, (void*)(long)(i+1));
    }
    
    for (int i = 0; i < N; i++) {
        pthread_join(spies[i], NULL);
    }
    
    should_staff_continue = 0;
    for (int i = 0; i < MAX_STAFF; i++) {
        pthread_join(staff[i], NULL);
    }
    
    for (int i = 0; i < TYPEWRITERS; i++) {
        sem_destroy(&typewriters[i]);
    }
    sem_destroy(&logbook);
    pthread_mutex_destroy(&logbook_mutex);
    pthread_mutex_destroy(&output_mutex);
    for (int i = 0; i < num_groups; i++) {
        pthread_mutex_destroy(&group_mutex[i]);
        sem_destroy(&group_semaphores[i]);
    }
    
    fclose(output_file);
    return 0;
}