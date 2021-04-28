#include <iostream>
#include <sstream>
#include <memory>
#include <raft>
/* #include <raftio> */
#include <cstdlib>
#include <cstring>
#include <getopt.h>
#include <stdio.h>      /* printf, scanf, NULL */
#include <stdlib.h>
#include <atomic>

#ifndef NOGEM5
#include <gem5/m5ops.h>
#else
inline void m5_reset_stats(unsigned a, unsigned b){}
inline void m5_dump_reset_stats(unsigned a, unsigned b){}
#endif

enum ALLOC_TYPE
{
    STD_ALLOC,
    DYN_ALLOC,
    VTL_ALLOC
};

void usage(char* arg0)
{
  std::cerr << "Usage:\t" << arg0 << " [-c -v -d -s -q[1-3]] n c t" << std::endl;
}

int global_sum = 0;

void parse_args(int argc, char** argv,
    unsigned* n, unsigned *c, unsigned *t, bool* check, ALLOC_TYPE* at, bool* sched)
{
  int opt;
  char* arg0 = argv[0];
  auto us = [arg0] () {usage(arg0);};
  int helper;
  while((opt = getopt(argc, argv, "scvdq:")) != -1)
  {
    std::ostringstream num_hwpar;
    switch(opt)
    {
      case 'v' :
        *at = VTL_ALLOC;
        break;
      case 'd' :
        *at = DYN_ALLOC;
        break;
      case 's' :
        *at = STD_ALLOC;
        break;
      case 'q' :
        helper = atoi(optarg);
        if (1 > helper || 64 < helper)
        {
          std::cerr << "You failed to properly specify the number of qthreads" << std::endl;
          us();
          exit(-4);
        }
        helper++;
        if(setenv("QT_NUM_SHEPHERDS", "1", 1) ||
            !(num_hwpar << helper) ||
            setenv("QT_HWPAR", num_hwpar.str().c_str(), 1) ||
            setenv("QT_NUM_WORKERS_PER_SHEPHERD", num_hwpar.str().c_str(), 1))
        {
          std::cerr << "Setting environment variables failed" << std::endl;
          us();
          exit(-5);
        }
        *sched = true;
        break;

      case 'c' :
        *check = true;
        break;
    }
  }
  const int num_required = 3;
  std::istringstream sarr[num_required];
  unsigned darr[num_required];
  unsigned i;
  for(i = 0; i < num_required; i++)
  {
    if(optind + i == argc)
    {
      std::cerr << "You have too few unsigned int arguments: " << i << " out of 3" << std::endl;
      us();
      exit(-3);
    }
    sarr[i] = std::istringstream(argv[optind + i]);
    if(!(sarr[i] >> darr[i]))
    {
      std::cerr << "Your argument at " << optind + i << " was malformed." << std::endl;
      std::cerr << "It should have been an unsigned int" << std::endl;
      us();
      exit(-2);
    }
  }
  if(i + optind != argc)
  {
    std::cerr << "You have too many arguments." << std::endl;
    us();
    exit(-1);
  }

  *n = darr[0];
  *c = darr[1];
  *t = darr[2];
}

class Data {
public:
    int num_points_to_process;
    unsigned *points_ptr;
    unsigned *dif_ptr;
    int num_centers;
    unsigned *centers;
    Data() : Data(0, 0, 0, 0, 0) {}
    Data(int num_points_to_process, unsigned *points_ptr, unsigned *dif_ptr,
            int num_centers, unsigned *centers) : 
        num_points_to_process(num_points_to_process), points_ptr(points_ptr), dif_ptr(dif_ptr),
        num_centers(num_centers), centers(centers) {
    }
    /* int &get_point(int i) const { */
    /*     return point_ptr[i]; */
    /* } */
    /* int &operator[](int i) { */
    /*     return data[i]; */
    /* } */
    /* int get_num_elem() { */
    /*     return num_elem; */
    /* } */
};

template<typename T>
class Initializer : public raft::kernel {
private:
    unsigned num_point;
    unsigned num_center;
    unsigned num_threads;
    unsigned *points;
    unsigned *distances;
    unsigned *centers;

public:
    Initializer(unsigned num_point, unsigned num_center, unsigned num_threads,
            unsigned *points, unsigned *distances, unsigned *centers
            ) : raft::kernel(), num_point(num_point), num_center(num_center), num_threads(num_threads),
                points(points), distances(distances), centers(centers) {

                    for (int i = 0; i < num_threads; i++) {
                        output.addPort< Data >(std::to_string(i));
                    }
    }

    virtual raft::kstatus run() {
        for (int i = 0; i < num_threads; i++) {
            int num_points_for_each_thread = num_point / num_threads;
            unsigned *point_ptr = points + i * num_points_for_each_thread;
            unsigned *dif_ptr = distances + i * num_points_for_each_thread;
            Data data_frame(num_point / num_threads, point_ptr,
                    dif_ptr, num_center, centers);
            output[std::to_string(i)].push(data_frame);
        }
        return raft::stop;
    }
};

template <class datatype>
class Distributor : public raft::kernel {
public:
    CLONE();
    Distributor() : raft::kernel()
    {
        input.addPort< datatype >( "in" );
        output.addPort< unsigned >( "out" );
    }
    // copy constructor for cloning
    Distributor(const Distributor &other) : raft::kernel()
    {
        input.addPort< datatype >( "in" );
        output.addPort< unsigned >( "out" );
    }

    virtual ~Distributor() = default;

    virtual raft::kstatus run()
    {
        Data dataframe;
        input["in"].pop(dataframe);
        for (unsigned i = 0; i < dataframe.num_points_to_process; i++) {
            /* dataframe.points_ptr[i] += dataframe.centers[0]; */
            output["out"].push(dataframe.points_ptr[i]);
        }
        return raft::proceed;
        //proceed
    }
};

template <class datatype>
class Kmeans : public raft::kernel {
private:
    unsigned num_points;
public:
    CLONE();
    Kmeans(unsigned num_points) : num_points(num_points), raft::kernel()
    {
        input.addPort< unsigned >( "in" );
        output.addPort< unsigned >( "out" );
    }
    // copy constructor for cloning
    Kmeans(const Kmeans &other) : raft::kernel()
    {
        input.addPort< unsigned >( "in" );
        output.addPort< unsigned >( "out" );
    }

    virtual ~Kmeans() = default;

    virtual raft::kstatus run()
    {
        std::cout << "executed------\n";
        unsigned sum = 0;
        for (unsigned i = 0; i < num_points; i++) {
            /* dataframe.points_ptr[i] += dataframe.centers[0]; */
            unsigned point;
            input["in"].pop(point);
            sum += point;
            /* dataframe.dif_ptr[i] = dataframe.centers[0] - dataframe.points_ptr[i]; */
        }
        output["out"].push(sum);
        return raft::proceed;
        //proceed
    }
};

template <class datatype>
class Accumalator : public raft::kernel {
private:
    unsigned num_points;
public:
    int num_threads;
    Accumalator(int num_threads, unsigned num_points) : raft::kernel(), num_threads(num_threads),
        num_points(num_points)
    {
        for (int i = 0; i < num_threads; i++) {
            input.addPort< unsigned >(std::to_string(i));
        }
    }
    virtual raft::kstatus run()
    {
        std::cout << "executed------2222\n";
        /* std::atomic<unsigned> sum = 0; */
        /* int sum = 0; */
        for (int i = 0; i < num_threads; i++) {
            unsigned sum;
            for (unsigned j = 0; j < num_points; j++) {
                input[std::to_string(i)].pop(sum);
                /* sum += dataframe.points_ptr[j]; */
                /* global_sum += dataframe.dif_ptr[j]; */
                global_sum += sum;
            }
        }
        return raft::proceed;
        //proceed
    }
};

void print_points(unsigned *points, unsigned num) {
    std::cout << "Points: ";
    for (unsigned i = 0; i < num; i++) {
        std::cout << points[i] << " ";
    }
    std::cout << std::endl;
}

void init_points(unsigned *points, unsigned num) {
    for (unsigned i = 0; i < num; i++) {
        /* points[i] = i % 3; */
        points[i] = 1;
    }
}

void init_centers(unsigned *centers, unsigned num) {
    for (unsigned i = 0; i < num; i++) {
        centers[i] = 1;
    }
}

int main(int argc, char **argv)
{
    unsigned n;
    unsigned c;
    unsigned t;
    bool check = false;
    bool sched = false;
    ALLOC_TYPE at = STD_ALLOC;
    parse_args(argc, argv, &n, &c, &t, &check, &at, &sched);
    /* std::cout << "passed num elem: " << n << c << t << std::endl; */

    // TODO: for now, assume n (number of points) is the multiple of 512
    /* n = 2048; */
    /* c = 3; */

    unsigned *points = (unsigned *)malloc(n * sizeof(unsigned));
    init_points(points, n);
    /* print_points(points, n); */
    unsigned *distances = (unsigned *)malloc(n * sizeof(unsigned));
    unsigned *centers = (unsigned *)malloc(sizeof(unsigned ) * c);
    //init_centers(centers, c);
   
    
    // TODO: reset m5 status
    m5_reset_stats(0,0);

    for (int it = 0; it < 3; it++) {
        Initializer<Data> initializer = Initializer<Data>(n, c, t, points, distances, centers);
        Distributor<Data> distributor = Distributor<Data>();
        Kmeans<Data> kmeans_kernel = Kmeans<Data>(n / t);
        Accumalator<Data> accumalator = Accumalator<Data>(t, n / t);
        raft::map m;

        m += initializer <= (distributor >> kmeans_kernel) >= accumalator;
        std::cout << "starting map..." << std::endl;
        if (at == STD_ALLOC) {
            if (sched) {
                m.exe<partition_dummy, pool_schedule, stdalloc, no_parallel>();
            } else {
                m.exe<partition_dummy, simple_schedule, stdalloc, no_parallel>();
            }
        }
        else if (at == DYN_ALLOC) {
            if (sched) {
                m.exe<partition_dummy, pool_schedule, dynalloc, no_parallel>();
            } else {
                m.exe<partition_dummy, simple_schedule, dynalloc, no_parallel>();
            }
        }
        else if (at == VTL_ALLOC) {
            if (sched) {
                m.exe<partition_dummy, pool_schedule, vlalloc, no_parallel>();
            } else {
                m.exe<partition_dummy, simple_schedule, vlalloc, no_parallel>();
            }
        }
        else {
            std::cerr << "no allocation mode, exiting..." << std::endl;
            exit(-1);
        }
        std::cout << "glboal sum: " << global_sum << std::endl;
        /* std::cout << "finishing map..." << std::endl; */

        /* print_points(points, n); */
    }

    
    free(points);
    free(distances);
    free(centers);

    return 0;
}
