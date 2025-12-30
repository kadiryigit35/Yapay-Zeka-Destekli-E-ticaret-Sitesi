import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/cart_provider.dart';
import 'main.dart';
import 'checkout_page.dart';
import 'models.dart';

class CartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Sepetim'),
      ),
      body: cart.items.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Sepetiniz boş'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Alışverişe Devam Et'),
            )
          ],
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (ctx, i) {
                final cartItem = cart.items.values.toList()[i];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                  child: ListTile(
                    leading: Image.network(
                      '${ApiService.baseUrl}/Upload/${cartItem.product.resim}',
                      width: 60,
                      fit: BoxFit.cover,
                    ),
                    title: Text(cartItem.product.adi),
                    subtitle: Text('Toplam: ₺${(cartItem.product.fiyat * cartItem.quantity).toStringAsFixed(2)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: () => cart.updateQuantity(cartItem.product.id, cartItem.quantity - 1),
                        ),
                        Text('${cartItem.quantity}'),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () => cart.updateQuantity(cartItem.product.id, cartItem.quantity + 1),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Card(
            margin: EdgeInsets.all(15),
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('Toplam Tutar', style: TextStyle(fontSize: 20)),
                  Chip(
                    label: Text('₺${cart.totalAmount.toStringAsFixed(2)}', style: TextStyle(color: Colors.white)),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  ElevatedButton(
                    child: Text('SİPARİŞ VER'),
                    onPressed: () async {
                      // Mevcut kullanıcıyı al (giriş yapmamışsa null olacaktır)
                      final User? user = await AuthService.getCurrentUser();

                      // Kontrol yapmadan doğrudan CheckoutPage'e yönlendir.
                      // CheckoutPage, user null ise misafir modunda çalışacaktır.
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CheckoutPage(user: user),
                        ),
                      );
                    },
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}