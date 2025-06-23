import 'package:tencent_effect_flutter/api/tencent_effect_api.dart';

class TeAppConfig {
  // 私有静态实例变量
  static final TeAppConfig _instance = TeAppConfig._internal();

  // 私有构造函数
  TeAppConfig._internal();

  // 公共访问点
  static TeAppConfig get instance => _instance;

  // 可选：防止通过序列化/反序列化创建新实例
  factory TeAppConfig() => _instance;



  EffectMode effectMode = EffectMode.PRO;




}