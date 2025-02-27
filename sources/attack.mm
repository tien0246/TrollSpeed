#pragma clang diagnostic ignored "-Wunused-variable"
#pragma clang diagnostic ignored "-Wunused-function"
#pragma clang diagnostic ignored "-Wframe-address"

#import <mach-o/dyld.h>
#import <mach-o/loader.h>
#import <mach-o/getsect.h>
#import <mach/mach.h>
#import <mach-o/dyld_images.h>

#include <iostream>
#include <unistd.h>
#include <stdio.h>
#include <vector>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include <sys/types.h>
#include <sys/sysctl.h>

NS_ASSUME_NONNULL_BEGIN

@interface attack : UIView

@end

NS_ASSUME_NONNULL_END


static NSTimer *getpidpro;

extern "C" kern_return_t mach_vm_region_recurse(
                                                vm_map_t                 map,
                                                mach_vm_address_t        *address,
                                                mach_vm_size_t           *size,
                                                uint32_t                 *depth,
                                                vm_region_recurse_info_t info,
                                                mach_msg_type_number_t   *infoCnt);

static pid_t GetGameProcesspid(char* GameProcessName) {
    size_t length = 0;
    static const int name[] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
    int err = sysctl((int *)name, (sizeof(name) / sizeof(*name)) - 1, NULL, &length, NULL, 0);
    if (err == -1) err = errno;
    if (err == 0) {
        struct kinfo_proc *procBuffer = (struct kinfo_proc *)malloc(length);
        if(procBuffer == NULL) return -1;
        sysctl((int *)name, (sizeof(name) / sizeof(*name)) - 1, procBuffer, &length, NULL, 0);
        int count = (int)length / sizeof(struct kinfo_proc);
        for (int i = 0; i < count; ++i) {
            const char *procname = procBuffer[i].kp_proc.p_comm;
            pid_t Processpid = procBuffer[i].kp_proc.p_pid;
            if(strstr(procname,GameProcessName)){
                return Processpid;
            }
        }
        // free(procBuffer);
    }
    return  -1;
}

static vm_map_offset_t GetGameModule_Base(char* GameProcessName) {
    vm_map_offset_t vmoffset = 0;
    vm_map_size_t vmsize = 0;
    uint32_t nesting_depth = 0;
    struct vm_region_submap_info_64 vbr;
    mach_msg_type_number_t vbrcount = 16;
    pid_t pid = GetGameProcesspid(GameProcessName);
    mach_port_t get_task;
    kern_return_t kret = task_for_pid(mach_task_self(), pid, &get_task);
    if (kret == KERN_SUCCESS) {
        mach_vm_region_recurse(get_task, &vmoffset, &vmsize, &nesting_depth, (vm_region_recurse_info_t)&vbr, &vbrcount);
    }
    return vmoffset;
}

@implementation attack
+ (void)load {
    getpidpro = [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            pid_t pid = GetGameProcesspid((char*)"VNID");
            if (pid) {
                NSLog(@"=================================================%d", pid);
                //  show pid on view
                UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
                label.text = [NSString stringWithFormat:@"%d", pid];
                label.textColor = [UIColor redColor];
                label.font = [UIFont systemFontOfSize:20];
                [[UIApplication sharedApplication].keyWindow.rootViewController.view addSubview:label];
            }
        });
    }];
    [[NSRunLoop currentRunLoop] addTimer:getpidpro forMode:NSRunLoopCommonModes];
}
@end