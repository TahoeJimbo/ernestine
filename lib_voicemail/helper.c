
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/file.h>
#include <errno.h>
#include <fcntl.h>

#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static char *programName;

static void usage(void) 
{
    fprintf(stderr, "Usage: %s {command} [args...]\n", programName);
    fprintf(stderr, "Commands: nextID {mailbox_dir}\n");
    fprintf(stderr, "\n");

    exit(1);
}

#define NEXT_ID "nextID"

static void nextID(char *path) 
{
    // Open the INDEX.txt specified by the path
    
    FILE *index;

    index = fopen(path, "r+");
    
    if (index == NULL) {
        printf("X: %s: %s\n", path, strerror(errno));
        exit(1);
    }

    //
    // Create an advisory lock on the box index.  Try every millisecond
    // and give up after half a second.
    //

    int attempts = 500;
    int result;

    int fd = fileno(index);

    while (attempts > 0) {

        result = flock(fd, LOCK_EX | LOCK_NB);

        if (result == 0) {
            break;
        }

        usleep(1000);
    }

    if (result != 0) {
        printf("X: Couldn't obtain lock on %s\n", path);
        fclose(index);
        exit(1);
    }

    //
    // Ok, we have the lock!
    //

    fseek(index, 0L, SEEK_SET);
    int unique;
    
    fscanf(index, "%d", &unique);

    unique++;

    fseek(index, 0L, SEEK_SET);

    fprintf(index, "%d\n", unique);

    flock(fd, LOCK_UN);
    
    fclose(index);
    
    printf("%d\n", unique);
}


main(int argc, char *argv[])
{
    int argIndex = 0;
        
    programName = argv[0];

    if (argc <= 1) usage();

    argc--;
    argIndex++;

    /* Decode the command */

    if (strncmp(argv[argIndex], NEXT_ID, sizeof(NEXT_ID)) == 0) {
        argc--;
        argIndex++;
        
        if (argc < 1) usage();
        
        nextID(argv[argIndex]);

        exit(0);
   }

    usage();
}
