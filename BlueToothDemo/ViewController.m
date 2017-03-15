//
//  ViewController.m
//  blueUseTest
//
//  Created by lichao on 2017/3/13.
//  Copyright © 2017年 lichao. All rights reserved.
//

/**
 服务和特征
 */

/**
 每个蓝牙4.0的设备都是通过服务和特征来展示自己的，一个设备必然包含一个或多个服务，每个服务下面又包含若干个特征。特征是与外界交互的最小单位。比如说，一台蓝牙4.0设备，用特征A来描述自己的出厂信息，用特征B来与收发数据等。
 服务和特征都是用UUID来唯一标识的，国际蓝牙组织为一些很典型的设备(比如测量心跳和血压的设备)规定了标准的service UUID(特征的UUID比较多，这里就不列举了),如下:
 */


//#define     BLE_UUID_ALERT_NOTIFICATION_SERVICE   0x1811
//#define     BLE_UUID_BATTERY_SERVICE   0x180F
//#define     BLE_UUID_BLOOD_PRESSURE_SERVICE   0x1810
//#define     BLE_UUID_CURRENT_TIME_SERVICE   0x1805
//#define     BLE_UUID_CYCLING_SPEED_AND_CADENCE   0x1816
//#define     BLE_UUID_DEVICE_INFORMATION_SERVICE   0x180A
//#define     BLE_UUID_GLUCOSE_SERVICE   0x1808
//#define     BLE_UUID_HEALTH_THERMOMETER_SERVICE   0x1809
//#define     BLE_UUID_HEART_RATE_SERVICE   0x180D
//#define     BLE_UUID_HUMAN_INTERFACE_DEVICE_SERVICE   0x1812
//#define     BLE_UUID_IMMEDIATE_ALERT_SERVICE   0x1802
//#define     BLE_UUID_LINK_LOSS_SERVICE   0x1803
//#define     BLE_UUID_NEXT_DST_CHANGE_SERVICE   0x1807
//#define     BLE_UUID_PHONE_ALERT_STATUS_SERVICE   0x180E
//#define     BLE_UUID_REFERENCE_TIME_UPDATE_SERVICE   0x1806
//#define     BLE_UUID_RUNNING_SPEED_AND_CADENCE   0x1814
//#define     BLE_UUID_SCAN_PARAMETERS_SERVICE   0x1813
//#define     BLE_UUID_TX_POWER_SERVICE   0x1804
//#define     BLE_UUID_CGM_SERVICE   0x181A


//外围设备名称
#define kPeripheralName         @"外围设备名称"
//服务的UUID
#define kServiceUUID            @"服务的UUID"
//特征的UUID
#define kCharacteristicUUID     @"特征的UUID"

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController ()<CBCentralManagerDelegate, CBPeripheralDelegate>

//蓝牙操作对象
@property(nonatomic, strong) CBCentralManager *manager;
//获取蓝牙设备信息的对象
@property(nonatomic, strong) CBPeripheral *peripheral;
//蓝牙设备读写服务操作对象
@property(nonatomic, strong) CBCharacteristic *characteristic;
//定时器
@property(nonatomic, strong) NSTimer *connectTimer;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    //创建数组来管理外设
//    self.peripherals = [NSMutableArray array];
    
}


#pragma mark 1 == UpdataState
/**
 连接蓝牙前先检查中心的蓝牙是否打开, 确认蓝牙打开后开始扫描蓝牙
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
        case CBManagerStateUnknown:
            
            NSLog(@"无法获取设备的蓝牙状态");
            
            break;
        case CBManagerStateResetting:
            
            NSLog(@"蓝牙重置");
            
            break;
        case CBManagerStateUnsupported:
            
            NSLog(@"该设备不支持蓝牙");
            
            break;
        case CBManagerStateUnauthorized:
            
            NSLog(@"未授权蓝牙权限");
            
            break;
        case CBManagerStatePoweredOff:
            
            NSLog(@"蓝牙已关闭");
            
            break;
        case CBManagerStatePoweredOn:
            
            NSLog(@"蓝牙已打开");
            //扫描语句:写nil表示扫描所有的蓝牙外设,如果传上面的kServiceUUID, 那么只能扫描出FFEO这个服务的外设
            [self.manager scanForPeripheralsWithServices:nil options:nil];
            break;
        default:
        {
            NSLog(@"未知的蓝牙错误");
        }
            break;
    }
}


#pragma mark 2 == 发现外设
/**
 成功扫描到了蓝牙会自动进入:didDiscoverPeripheral这个函数
 
 @param peripheral peripheral.name 扫描到的蓝牙的名字
 @param RSSI 距离
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    /*
     外设蓝牙名字修改后搜索不到的问题:
     一般在日常使用中蓝牙的名称并不需要经常改动，往往需求是造化弄人的。外设较多时我们一般会根据外设的名称进行过滤，
     在此委托方法中，我么可以直接通过 peripheral.name 的属性来过滤，此时好像并没有什么问题，直到蓝牙的名称被修改后
     部分蓝牙怎么就搜索不到了，此时我发现蓝牙修改前的名字却能搜索到，与硬件开发的同事几经交涉后，蓝牙的名字确确实实已经被
     修改。
     解决办法：
     在蓝牙的广播数据中 根据@"kCBAdvDataLocalName"这个 key 便可获得准确的蓝牙名称（在 github上一个优秀的蓝牙开源项目中发现的）
     至于为什么从 peripheral.name 这个属性拿到的名称不准确仍是不解，知道的书友麻烦告知一下！
     */
    NSString *localName = [[advertisementData objectForKey:@"kCBAdvDataLocalName"] lowercaseString];
    NSString *peripheralName = [peripheral.name lowercaseString];
    NSLog(@"广播--:%@ 设备--:%@",localName, peripheralName);
    
    //要连接蓝牙的名
    NSString *MyBlueToothName = @"lichao的macbook pro";
    self.peripheral = peripheral;
    
    /**
     连接设备
     */
    if ([localName isEqualToString:MyBlueToothName ]|| [peripheralName isEqualToString:MyBlueToothName]) {
        self.peripheral.delegate = self;
        [self connect:peripheral];
    }
}

//连接指定的设备
- (BOOL)connect:(CBPeripheral *)peripheral
{
    NSLog(@"正在连接指定设备");
    
    [self.manager connectPeripheral:peripheral options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
    
    return (YES);  
}

#pragma mark 3 == 成功连接Peripheral
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    //连接成功之后寻找服务,传nil会寻找所有服务
    NSLog(@"连接成功");
    [peripheral discoverServices:nil];
    //连接成功, 停止扫描
    [self.manager stopScan];
}

#pragma mark == 发现服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
//    for (CBService *service in peripheral.services) {
//        NSLog(@"servicesUUID = %@", service.UUID);
//        
//        [peripheral discoverCharacteristics:nil forService:service];
//    }
    
    if (!error) {
        for (CBService *service in peripheral.services) {
            NSLog(@"serviceUUID:%@", service.UUID.UUIDString);
            //发现特定服务的特征值
            if ([service.UUID.UUIDString isEqualToString:kServiceUUID]) {
                [service.peripheral discoverCharacteristics:nil forService:service];
            }
        }
    }

}

#pragma mark == 发现Characteristics
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSLog(@"Characteristics---%@", [service characteristics]);
    // 遍历服务中所有的特征值
//    for (CBCharacteristic *characteristic in service.characteristics)
//    {
//         NSLog(@"发现--characteristics:%@ for service: %@", characteristic.UUID, service.UUID);
//    }
    
    // 遍历服务中所有的特征值
    for (CBCharacteristic *characteristic in service.characteristics)
    {
        // 找到我们需要的特征
        if ([characteristic.UUID isEqual:kCharacteristicUUID])
        {
            NSLog(@"Discovered characteristics:%@ for service: %@", characteristic.UUID, service.UUID);
            
//            _readCharacteristic = characteristic;//保存读的特征
            
            /**
                找到特征以后进行的操作
             */
            
            break;
        }  
    }
    
}


#pragma mark == 外设断开连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"连接中断---%@", error);
}

#pragma mark -- 连接失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"连接失败---%@", error);
}


@end

