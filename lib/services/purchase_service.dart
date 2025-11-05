import 'dart:async';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  // 产品ID - 需要在Google Play Console中配置
  static const String premiumProductId = 'family_tree_premium';
  
  // 购买状态
  bool _isPremium = false;
  bool get isPremium => _isPremium;
  
  // 产品详情
  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;
  
  // 购买状态流
  final StreamController<bool> _premiumStatusController = StreamController<bool>.broadcast();
  Stream<bool> get premiumStatusStream => _premiumStatusController.stream;
  
  // 初始化购买服务
  Future<void> initialize() async {
    // 加载本地购买状态
    await _loadPurchaseStatus();
    
    // 设置购买监听器
    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription.cancel(),
      onError: (error) => print('Purchase stream error: $error'),
    );
    
    // 获取产品信息
    await _loadProducts();
    
    // 恢复之前的购买
    await _restorePurchases();
  }
  
  // 加载产品信息
  Future<void> _loadProducts() async {
    final Set<String> productIds = {premiumProductId};
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);
    
    if (response.notFoundIDs.isNotEmpty) {
      print('Products not found: ${response.notFoundIDs}');
    }
    
    _products = response.productDetails;
  }
  
  // 购买产品
  Future<bool> purchasePremium() async {
    if (_products.isEmpty) {
      await _loadProducts();
    }
    
    if (_products.isEmpty) {
      print('No products available for purchase');
      return false;
    }
    
    final ProductDetails productDetails = _products.firstWhere(
      (product) => product.id == premiumProductId,
      orElse: () => _products.first,
    );
    
    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: productDetails,
    );
    
    try {
      final bool success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      return success;
    } catch (e) {
      print('Purchase failed: $e');
      return false;
    }
  }
  
  // 恢复购买
  Future<void> _restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      print('Restore purchases failed: $e');
    }
  }
  
  // 处理购买更新
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      _handlePurchase(purchaseDetails);
    }
  }
  
  // 处理单个购买
  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.status == PurchaseStatus.purchased ||
        purchaseDetails.status == PurchaseStatus.restored) {
      
      if (purchaseDetails.productID == premiumProductId) {
        await _setPremiumStatus(true);
        _premiumStatusController.add(true);
      }
      
      // 完成购买
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }
  
  // 保存购买状态
  Future<void> _setPremiumStatus(bool isPremium) async {
    _isPremium = isPremium;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', isPremium);
  }
  
  // 加载购买状态
  Future<void> _loadPurchaseStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool('is_premium') ?? false;
  }
  
  // 检查是否已购买高级版
  Future<bool> checkPremiumStatus() async {
    await _loadPurchaseStatus();
    return _isPremium;
  }
  
  // 获取产品价格
  String getProductPrice() {
    if (_products.isEmpty) return '¥12.00'; // 默认价格
    
    final product = _products.firstWhere(
      (p) => p.id == premiumProductId,
      orElse: () => _products.first,
    );
    
    return product.price;
  }
  
  // 释放资源
  void dispose() {
    _subscription.cancel();
    _premiumStatusController.close();
  }
}

