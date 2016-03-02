//
//  ListTableViewController.m
//  CoreBluetooth
//
//  Created by 赵亚琴 on 16/1/29.
//  Copyright © 2016年 赵亚琴. All rights reserved.
//

#import "ListTableViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface ListTableViewController () <CBCentralManagerDelegate, CBPeripheralDelegate> {
    // 系统蓝牙设备管理对象，可以理解为主设备，通过他去扫描和连接外设
    CBCentralManager *manager;
}

@property (nonatomic, strong) NSMutableArray *allPeripheral;

@end

@implementation ListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#warning Incomplete implementation, return the number of sections
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#warning Incomplete implementation, return the number of rows
    return self.allPeripheral.count;
}
- (IBAction)start:(UIBarButtonItem *)sender {
    // // 初始化并设置委托和线程队列
    manager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
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
            [manager scanForPeripheralsWithServices:nil options:nil];
            break;
        }
            
        default:
            break;
    }
}

// 扫描到设备就会调用此方法
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    
    NSLog(@"扫描到设备：%@", peripheral.name);
    if (peripheral.name != nil) {
        
//        NSLog(@"%@", self.allPeripheral);
        
        [self.allPeripheral addObject:peripheral];
        
//        [manager connectPeripheral:peripheral options:nil];

    }
    
    [self.tableView reloadData];
    // 扫描到设备之后可以连接设备
    // 选择以p开头的设备进行连接
//    if ([peripheral.name hasPrefix:@"p"]) {
//        // 一个主设备最多能连接7个外设，每个外设最多只能给一个主设备连接，连接成功，失败，断开连接都有各自的委托
//        // 连接设备
//        [manager connectPeripheral:peripheral options:nil];
//    }
    
}
#pragma mark - 连接外设

// 连接设备成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"连接到设备：%@", peripheral.name);
    // 设置外设委托
    [peripheral setDelegate:self];
    // 扫描外设
    [peripheral discoverServices:nil];
    
}

// 连接设备失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"%s", __func__);
}
// 断开连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"%s", __func__);
}

// 扫描到service
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (!error) {
        for (CBService *service in peripheral.services) {
            NSLog(@"%@", service.UUID);
            // 开始扫描外设的特征
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
}


#pragma mark - 获取外设的特征
// 扫描到Characteristics
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    NSLog(@"%@", service.UUID);
    
    // 遍历服务中的特征
    for (CBCharacteristic *characteristic in service.characteristics) {
        NSLog(@"%@, Characteristic: %@", service.UUID, characteristic.UUID);
        // 获取Characteristic的值
        [peripheral readValueForCharacteristic:characteristic];
        
        // 通知
        [peripheral setNotifyValue:YES forCharacteristic:characteristic];
    }
}
// 获取Characteristic 的值
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    // 打印Characteristic 的UUID 和值
    // 注意value的类型是NSData。具体开发时会根据外设协议制定的方式去解析数据
    NSLog(@"%@, value:%@", characteristic.UUID, characteristic.value);
    
}
// 特征值被更新之后
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"收到特征更新通知");
    
}
// 搜所到Characteristic的descriptors
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"uuid:%@", characteristic.UUID);
    for (CBDescriptor *d in characteristic.descriptors) {
        NSLog(@"descriptor uuid: %@", d.UUID);
        [peripheral readValueForDescriptor:d];
    }
    
}
// 获取到descriptors的值
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error {
    // 打印出DescriptorsUUID 和value
    // 这个descriptor都是对于characteristic的描述，一般都是字符串，所以这里我们转换成字符串去解析
    NSLog(@"characteristic uuid: %@, value:%@", [NSString stringWithFormat:@"%@", descriptor.UUID], descriptor.value);
}

#pragma mark - 写数据到characteristic中
//写数据
-(void)writeCharacteristic:(CBPeripheral *)peripheral
            characteristic:(CBCharacteristic *)characteristic
                     value:(NSData *)value{
    
    //打印出 characteristic 的权限，可以看到有很多种，这是一个NS_OPTIONS，就是可以同时用于好几个值，常见的有read，write，notify，indicate，知知道这几个基本就够用了，前连个是读写权限，后两个都是通知，两种不同的通知方式。
    /*
     typedef NS_OPTIONS(NSUInteger, CBCharacteristicProperties) {
     CBCharacteristicPropertyBroadcast                                              = 0x01,
     CBCharacteristicPropertyRead                                                   = 0x02,
     CBCharacteristicPropertyWriteWithoutResponse                                   = 0x04,
     CBCharacteristicPropertyWrite                                                  = 0x08,
     CBCharacteristicPropertyNotify                                                 = 0x10,
     CBCharacteristicPropertyIndicate                                               = 0x20,
     CBCharacteristicPropertyAuthenticatedSignedWrites                              = 0x40,
     CBCharacteristicPropertyExtendedProperties                                     = 0x80,
     CBCharacteristicPropertyNotifyEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)        = 0x100,
     CBCharacteristicPropertyIndicateEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)  = 0x200
     };
     
     */
    NSLog(@"%lu", (unsigned long)characteristic.properties);
    
    
    //只有 characteristic.properties 有write的权限才可以写
    if(characteristic.properties & CBCharacteristicPropertyWrite){
        /*
         最好一个type参数可以为CBCharacteristicWriteWithResponse或type:CBCharacteristicWriteWithResponse,区别是是否会有反馈
         */
        [peripheral writeValue:value forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    }else{
        NSLog(@"该字段不可写！");
    }
    
    
}

#pragma mark - 订阅Characteristic的通知
//设置通知
-(void)notifyCharacteristic:(CBPeripheral *)peripheral
             characteristic:(CBCharacteristic *)characteristic{
    //设置通知，数据通知会进入：didUpdateValueForCharacteristic方法
    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
    
}

//取消通知
-(void)cancelNotifyCharacteristic:(CBPeripheral *)peripheral
                   characteristic:(CBCharacteristic *)characteristic{
    
    [peripheral setNotifyValue:NO forCharacteristic:characteristic];
}

#pragma mark - 断开连接
//停止扫描并断开连接
-(void)disconnectPeripheral:(CBCentralManager *)centralManager
                 peripheral:(CBPeripheral *)peripheral{
    //停止扫描
    [centralManager stopScan];
    //断开连接
    [centralManager cancelPeripheralConnection:peripheral];
}

- (NSMutableArray *)allPeripheral {
    if (!_allPeripheral) {
        _allPeripheral = [NSMutableArray array];
    }
    return _allPeripheral;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIdentifier"];
    
    // Configure the cell...
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"reuseIdentifier"];
        cell.textLabel.text = [self.allPeripheral[indexPath.row] name];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CBPeripheral *p = self.allPeripheral[indexPath.row];
    [manager connectPeripheral:p options:nil];
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
