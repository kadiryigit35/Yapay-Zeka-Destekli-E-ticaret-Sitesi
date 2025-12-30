import 'package:flutter/foundation.dart';
import '../models.dart';

class CartProvider with ChangeNotifier {
  final Map<int, CartItem> _items = {};

  Map<int, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.product.fiyat * cartItem.quantity;
    });
    return total;
  }

  void addToCart(Product product) {
    if (_items.containsKey(product.id)) {
      _items.update(
        product.id,
            (existingCartItem) {
          existingCartItem.quantity++;
          return existingCartItem;
        },
      );
    } else {
      _items.putIfAbsent(
        product.id,
            () => CartItem(product: product),
      );
    }
    notifyListeners();
  }

  void updateQuantity(int productId, int quantity) {
    if (_items.containsKey(productId)) {
      if (quantity > 0) {
        _items.update(productId, (item) {
          item.quantity = quantity;
          return item;
        });
      } else {
        _items.remove(productId);
      }
      notifyListeners();
    }
  }

  void removeFromCart(int productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
