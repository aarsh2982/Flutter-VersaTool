import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lottie/lottie.dart';

void main() {
  runApp(const CurrencyConverterApp());
}

class CurrencyConverterApp extends StatelessWidget {
  const CurrencyConverterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.teal,
      ),
      home: const CurrencyConverterScreen(),
    );
  }
}

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final TextEditingController _amountController = TextEditingController();
  double _convertedAmount = 0.0;
  String _fromCurrency = 'USD';
  String _toCurrency = 'INR';
  bool _isLoading = false;
  Map<String, double> _exchangeRates = {};

  final List<String> _currencies = [
    'USD',
    'EUR',
    'INR',
    'GBP',
    'AUD',
    'CAD',
    'JPY',
    'CNY'
  ];

  @override
  void initState() {
    super.initState();
    _fetchExchangeRates();
  }

  Future<void> _fetchExchangeRates() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/$_fromCurrency'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _exchangeRates = Map<String, double>.from(data['rates']);
          _convertCurrency();
        });
      } else {
        throw Exception('Failed to fetch exchange rates');
      }
    } catch (e) {
      print('Error fetching rates: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _convertCurrency() {
    final double amount = double.tryParse(_amountController.text) ?? 0.0;
    final double rate = _exchangeRates[_toCurrency] ?? 1.0;
    setState(() {
      _convertedAmount = amount * rate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Lottie.asset('assets/money_animation.json', height: 150),
              const SizedBox(height: 10),
              Text(
                'Currency Converter',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.tealAccent,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Enter Amount',
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) => _convertCurrency(),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDropdown(_fromCurrency, (val) {
                    setState(() {
                      _fromCurrency = val!;
                      _fetchExchangeRates();
                    });
                  }),
                  Icon(Icons.swap_horiz, color: Colors.white, size: 40),
                  _buildDropdown(_toCurrency, (val) {
                    setState(() {
                      _toCurrency = val!;
                      _convertCurrency();
                    });
                  }),
                ],
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : Text(
                      '$_convertedAmount $_toCurrency',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.tealAccent,
                      ),
                    ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchExchangeRates,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Update Rates'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String value, Function(String?) onChanged) {
    return DropdownButton<String>(
      value: value,
      dropdownColor: Colors.black,
      style: const TextStyle(color: Colors.white, fontSize: 18),
      onChanged: onChanged,
      items: _currencies.map((currency) {
        return DropdownMenuItem(
          value: currency,
          child: Text(currency),
        );
      }).toList(),
    );
  }
}
