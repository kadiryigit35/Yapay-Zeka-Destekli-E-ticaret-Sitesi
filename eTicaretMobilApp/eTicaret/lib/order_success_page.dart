import 'package:flutter/material.dart';
import 'main.dart';

class OrderSuccessPage extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const OrderSuccessPage({Key? key, required this.orderData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String orderNumber = orderData['siparisNumarasi'] ?? 'N/A';

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 100),
              SizedBox(height: 24),
              Text('Siparişiniz Alındı!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Text('Sipariş Numaranız: $orderNumber', style: TextStyle(fontSize: 16)),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => HomePage()),
                        (Route<dynamic> route) => false,
                  );
                },
                child: Text('Alışverişe Devam Et'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
