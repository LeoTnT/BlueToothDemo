# BlueToothDemo

这篇文章主要包括iOS蓝牙开发的简介以及如果进行蓝牙开发, 具体的蓝牙知识不再详细介绍了.
>iOS蓝牙开发的实现基本上都是基于<CoreBlueTooth.framework>这个框架的, 这是目前世界上最流行的框架
可用于第三方蓝牙设备交互, 必须要支持蓝牙4.0
硬件至少是4s, 系统至少是iOS6
蓝牙4.0以低功耗著称, 一般也叫BLE(BlueTooth Low Energy)

###Core Bluetooth的基本常识
***
>* 每个蓝牙4.0设备都是通过服务(Service)和特征(Characteristic)来展示自己的
*  一个设备包含一个或多个服务, 每个服务下面又包含若干个特征
*  特征是与人交互的最小单位
*  服务特征都是用UUID来唯一标识的, 通过UUID就能区别不同的服务和特征
*  设备里面各个服务和特征的功能, 都是由蓝牙设备硬件厂商提供, 比如哪些是用来交互, 哪些可以获取模块信息等等.

###Core Bluetooth的开发步骤
***
#####建立中心设备:
    CBCentralManager *manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];

#####扫描外设:
    #pragma mark 1
//扫描语句:写nil表示扫描所有的蓝牙外设,如果传上面的kServiceUUID, 那么只能扫描出这个Service的Peripherals
    [self.manager scanForPeripheralsWithServices:nil options:nil];

    #pragma mark 2 == 发现外设
    /**
    成功扫描到了蓝牙会自动进入:didDiscoverPeripheral这个函数

    @param peripheral peripheral.name 扫描到的蓝牙的名字
    @param RSSI 距离
    */
    - (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
    {
        NSString *localName = [[advertisementData objectForKey:@"kCBAdvDataLocalName"] lowercaseString];
        NSString *peripheralName = [peripheral.name lowercaseString];
        NSLog(@"广播--:%@ 设备--:%@ 距离--:%@",localName, peripheralName, RSSI);

        //要连接蓝牙的名
        NSString *MyBlueToothName = @"要连接蓝牙的名";
        self.peripheral = peripheral;

        /**
        连接设备
        */
        if ([localName isEqualToString:MyBlueToothName ]|| [peripheralName isEqualToString:MyBlueToothName]) {
            self.peripheral.delegate = self;
            [self connect:peripheral];
        }
    }

    #pragma mark 3 == 成功连接Peripheral
    /**
    连接设备成功后会调用该方法
    */
    - (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
        //传nil会寻找所有服务
        NSLog(@"连接成功");
        [peripheral discoverServices:nil];
        //连接成功, 停止扫描
        [self.manager stopScan];
    }

/**
连接失败会调用该方法
*/
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
NSLog(@"连接失败---%@", error);
}
#####连接外设:
//连接指定的设备
- (BOOL)connect:(CBPeripheral *)peripheral
{
NSLog(@"正在连接指定设备");

[self.manager connectPeripheral:peripheral options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];

return (YES);  
}
#####扫描外设中的服务和特征:
#pragma mark 4 == 发现服务
/**
找到server后会调用该方法
*/
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{ 
if (peripheral != self.peripheral) {
NSLog(@"Wrong peripheral");
return;
}
if (error) {
NSLog(@"Error---%@", error);
return;
}

if (!error) {
for (CBService *service in peripheral.services) {
NSLog(@"serviceUUID:%@", service.UUID.UUIDString);
//发现特定服务的特征值
if ([service.UUID.UUIDString isEqualToString:kServiceUUID]) {
[service.peripheral discoverCharacteristics:nil forService:service];
return;
}
}
}
}

#pragma mark 5 == 发现Characteristics

/**
找到Characteristics后会调用该方法
*/
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
if (peripheral != self.peripheral) {
NSLog(@"Wrong peripheral");
return;
}
if (error) {
NSLog(@"Error---%@", error);
return;
}

// 遍历服务中所有的特征值
for (CBCharacteristic *characteristic in [service characteristics])
{
// 找到我们需要的特征
if ([characteristic.UUID isEqual:kCharacteristicUUID])
{
NSLog(@"serviceUUID--:%@", service.UUID);
NSLog(@"CharacteristicsUUID--:%@", characteristic.UUID);

self.characteristic = characteristic;

/**
找到特征以后进行的操作
*/
//            //我们可以使用readValueForCharacteristic:来读取数据,如果数据是不断更新的，则可以使用setNotifyValue:forCharacteristic:来实现只要有新数据，就获取
//            [self.peripheral readValueForCharacteristic:self.characteristic];
[self.peripheral setNotifyValue:YES forCharacteristic:self.characteristic];


break;
}  
}
}

#####利用特征与外设做数据交互
#pragma mark 6 == 获取设备返回的数据
/**
读取到数据就会调用该方法
*/
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
NSData *data = characteristic.value;

//
NSLog(@"data = %@", data);
}

#pragma mark Other == 数据交互

/**
向设备写数据

@param data 要写入的数据
*/
- (void)writeValue:(NSData *)data
{
[self.peripheral writeValue:data forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];
}

/**
当writeValue: forCharacteristic: type:方法被调用的时候就会调用该方法
*/
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error

{
//查询数据是否写入
NSLog(@"%@", characteristic.value);
}
#####断开连接
#pragma mark == 外设断开连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
NSLog(@"连接中断---%@", error);
}


######这只是蓝牙开发的一个流程, 真正用到项目中的话还是需要自己不断学习和了解才能运用到蓝牙项目当中. 不过当你真正了解了蓝牙的相关知识就会发现, 实际上比想象的要更简单.
附上demo链接, 如有不懂, 请下载demo另行查看:
https://github.com/LeoTnT/BlueToothDemo
