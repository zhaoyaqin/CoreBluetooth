//
//  CBPeripheralViewController.m
//  CoreBluetooth
//
//  Created by 赵亚琴 on 16/1/29.
//  Copyright © 2016年 赵亚琴. All rights reserved.
//

#import "CBPeripheralViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>


static NSString *const ServiceUUID1 =  @"FFF0";
static NSString *const notiyCharacteristicUUID =  @"FFF1";
static NSString *const readwriteCharacteristicUUID =  @"FFF2";
static NSString *const ServiceUUID2 =  @"FFE0";
static NSString *const readCharacteristicUUID =  @"FFE1";
static NSString * const LocalNameKey =  @"myPeripheral";

@interface CBPeripheralViewController () <CBPeripheralManagerDelegate> {
    // 外围管理者
    CBPeripheralManager *manager;
    // 服务的个数
    NSInteger sericeNum;
    // 计时器
    NSTimer *timer;
}
@property (weak, nonatomic) IBOutlet UILabel *info;



@end

@implementation CBPeripheralViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)start:(id)sender {
    
    // 初始化CBPeripheralManager
    manager = [[CBPeripheralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue() options:nil];
    
}

#pragma mark - CBPeripheralManagerDelegate
// 必须实现的方法
// peripheral状态改变
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    switch (peripheral.state) {
            // 判断蓝牙设备的状态，开启了则调用
        case CBPeripheralManagerStatePoweredOn: {
            self.info.text = [NSString stringWithFormat:@"设备%@已经打开", LocalNameKey];
            [self setUp];

            break;
        }
        case CBPeripheralManagerStatePoweredOff: {
            self.info.text = @"设备没有开启";
            break;
        }
        case CBPeripheralManagerStateUnsupported: {
            self.info.text = @"CBPeripheralManagerStateUnsupported";
            break;
        }
            
        default:
            break;
    }
}

#pragma mark  - 配置blueTooch
- (void)setUp {
    // characteristics字段的描述
    CBUUID *CBUUIDCharacteristicUserDescriptionStringUUID = [CBUUID UUIDWithString:CBUUIDCharacteristicUserDescriptionString];
    CBMutableCharacteristic *notityCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:notiyCharacteristicUUID] properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable];
    //
    CBMutableCharacteristic *readwirteCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:readCharacteristicUUID] properties:CBCharacteristicPropertyWrite | CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable | CBAttributePermissionsWriteable];
    // 设置desciption
    CBMutableDescriptor *readwriteCharacteristicDescription1 = [[CBMutableDescriptor alloc] initWithType:CBUUIDCharacteristicUserDescriptionStringUUID value:@"name"];
    [readwirteCharacteristic setDescriptors:@[readwriteCharacteristicDescription1]];
    
    CBMutableCharacteristic *readCharacteristic = [[CBMutableCharacteristic alloc]initWithType:[CBUUID UUIDWithString:readCharacteristicUUID] properties:CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable];
    //service1初始化并加入两个characteristics
    CBMutableService *service1 = [[CBMutableService alloc]initWithType:[CBUUID UUIDWithString:ServiceUUID1] primary:YES];
    [service1 setCharacteristics:@[notityCharacteristic,readwirteCharacteristic]];
    //service2初始化并加入一个characteristics
    CBMutableService *service2 = [[CBMutableService alloc]initWithType:[CBUUID UUIDWithString:ServiceUUID2] primary:YES];
    [service2 setCharacteristics:@[readCharacteristic]];
    //添加后就会调用代理的- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
    [manager addService:service1];
    [manager addService:service2];
}

// peripheral 添加了service
- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error {
    if (!error) {
        sericeNum++;
    }
    // 我们添加了两个服务，所以想两次都添加完成之后采取发送广播
    if (sericeNum == 2) {
        [manager startAdvertising:@
         {CBAdvertisementDataServiceUUIDsKey: @[[CBUUID UUIDWithString:ServiceUUID1],[CBUUID UUIDWithString:ServiceUUID2]], CBAdvertisementDataLocalNameKey: LocalNameKey}];
    }
}

-(void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error {
    NSLog(@"in peripheraManagerDidStartAdvertisiong");
}


#pragma mark - 对central的操作进行响应
// 订阅characteristics
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
    NSLog(@"订阅了%@的数据", characteristic.UUID);
    timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(sendData:) userInfo:characteristic repeats:YES];
    
}
// 取消订阅
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {
    NSLog(@"取消订阅%@的数据", characteristic.UUID);
    // 取消回应
    [timer invalidate];
    timer = nil;
}

- (BOOL)sendData:(NSTimer *)t {
    CBMutableCharacteristic *characteristic = t.userInfo;
    NSDateFormatter *dft = [[NSDateFormatter alloc] init];
    [dft setDateFormat:@"ss"];
    //执行回应centeral通知数据
    return  [manager updateValue:[[dft stringFromDate:[NSDate date]] dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:(CBMutableCharacteristic *)characteristic onSubscribedCentrals:nil];
}

//读characteristics请求
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request{
    NSLog(@"didReceiveReadRequest");
    //判断是否有读数据的权限
    if (request.characteristic.properties & CBCharacteristicPropertyRead) {
        NSData *data = request.characteristic.value;
        [request setValue:data];
        //对请求作出成功响应
        [manager respondToRequest:request withResult:CBATTErrorSuccess];
    }else{
        [manager respondToRequest:request withResult:CBATTErrorWriteNotPermitted];
    }
}
//写characteristics请求
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests{
    NSLog(@"didReceiveWriteRequests");
    CBATTRequest *request = requests[0];
    //判断是否有写数据的权限
    if (request.characteristic.properties & CBCharacteristicPropertyWrite) {
        //需要转换成CBMutableCharacteristic对象才能进行写值
        CBMutableCharacteristic *c =(CBMutableCharacteristic *)request.characteristic;
        c.value = request.value;
        [manager respondToRequest:request withResult:CBATTErrorSuccess];
    }else{
        [manager respondToRequest:request withResult:CBATTErrorWriteNotPermitted];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
