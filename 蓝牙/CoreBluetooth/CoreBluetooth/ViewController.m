//
//  ViewController.m
//  CoreBluetooth
//
//  Created by 赵亚琴 on 16/1/29.
//  Copyright © 2016年 赵亚琴. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController () <CBCentralManagerDelegate>

// 系统蓝牙设备管理对象，可以理解为主设备，通过他去扫描和连接外设
@property (nonatomic, strong) CBCentralManager *manager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (CBCentralManager *)manager {
    if (!_manager) {
        // 初始化并设置委托和线程队列
        _manager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
    }
    return _manager;
}

#pragma mark - CBCentralManagerDelegate
// 必须实现的方法
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    NSLog(@"%s", __func__);
    switch (central.state) {
        case CBCentralManagerStateUnknown: {
            NSLog(@"---CBCentralManagerStateUnknown");
            break;
        }
        case CBCentralManagerStateResetting: {
            NSLog(@"---CBCentralManagerStateResetting");
            break;
        }
        case CBCentralManagerStateUnsupported: {
            NSLog(@"----CBCentralManagerStateUnsupported");
            break;
        }
        case CBCentralManagerStatePoweredOff: {
            NSLog(@"---CBCentralManagerStatePoweredOff");
            break;
        }
        case CBCentralManagerStateUnauthorized: {
            NSLog(@"---CBCentralManagerStateUnauthorized");
            break;
        }
        case CBCentralManagerStatePoweredOn: {
            NSLog(@"---CBCentralManagerStatePoweredOn");
            // 开始扫描周围的外设
            [self.manager scanForPeripheralsWithServices:nil options:nil];
            break;
        }
            
        default:
            break;
    }
}

// 扫描到设备就会调用此方法
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    
    NSLog(@"扫描到设备：%@", peripheral.name);
    // 扫描到设备之后可以连接设备
    if ([peripheral.name hasPrefix:@"p"]) {
        // 一个主设备最多能连接7个外设，每个外设最多只能给一个主设备连接，连接成功，失败，断开连接都有各自的委托
        // 连接设备
        
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
