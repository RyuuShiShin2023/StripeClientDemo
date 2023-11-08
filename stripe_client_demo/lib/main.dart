import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

void main() {
  Stripe.publishableKey =
      'pk_test_51O9RVjECnWC5p0a0hUU95I5M7rfluvfYqVk62pajo0LSdAYgulXeHd5EQsSrXhWuJecBVPuvUxd4lkqVNC0TI5kj00KkdUtlSC';
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              try {
                await Stripe.instance.initPaymentSheet(
                  paymentSheetParameters: SetupPaymentSheetParameters(
                    merchantDisplayName: 'Flutter Stripe Example',
                    intentConfiguration: IntentConfiguration(
                      mode: const IntentMode(currencyCode: 'jpy', amount: 1000),
                      confirmHandler: (result, shouldSavePaymentMethod) async {
                        try {
                          final response = await Dio().post(
                            'http://192.168.100.159:3000/first.php',
                            data: {
                              'payment_method_id': result.id,
                              'should_save_payment_method':
                                  shouldSavePaymentMethod,
                            },
                          );
                          final Map<String, String> map =
                              Map.castFrom(json.decode(response.data));
                          Stripe.instance.intentCreationCallback(
                            IntentCreationCallbackParams(
                              clientSecret: map['client_secret'],
                            ),
                          );
                        } on Exception catch (e) {
                          debugPrint('Dio Error.\nerror: $e');
                        }
                      },
                    ),
                  ),
                );
                await Stripe.instance.presentPaymentSheet();
              } on StripeException catch (e) {
                final error = e.error;
                switch (error.code) {
                  case FailureCode.Canceled:
                    debugPrint('キャンセルされました.\nerror: $error');
                    break;
                  case FailureCode.Failed:
                    debugPrint('エラーが発生しました.\nerror: $error');
                    break;
                  case FailureCode.Timeout:
                    debugPrint('タイムアウトしました.\nerror: $error');
                    break;
                }
              }
            },
            child: const Text('Pay'),
          ),
        ),
      ),
    );
  }
}
