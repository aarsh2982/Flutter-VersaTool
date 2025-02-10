import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  double? _convertedAmount;
  String _fromCurrency = 'USD';
  String _toCurrency = 'INR';
  bool _isLoading = false;
  Map<String, double> _exchangeRates = {};
  String? _errorMessage;

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
      _errorMessage = null;
    });

    try {
      // Using a free API from FloatRates
      final response = await http.get(
        Uri.parse('https://open.er-api.com/v6/latest/USD'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        Map<String, double> rates = {};

        // Parse the rates from the response
        data['rates'].forEach((key, value) {
          if (_currencies.contains(key)) {
            rates[key] = value.toDouble();
          }
        });

        setState(() {
          _exchangeRates = rates;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load exchange rates');
      }
    } catch (e) {
      // If the first API fails, try a backup API
      try {
        final response = await http.get(
          Uri.parse('https://api.frankfurter.app/latest?from=USD'),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          Map<String, double> rates = {'USD': 1.0}; // Add USD manually as base

          data['rates'].forEach((key, value) {
            if (_currencies.contains(key)) {
              rates[key] = value.toDouble();
            }
          });

          setState(() {
            _exchangeRates = rates;
            _isLoading = false;
          });
        } else {
          throw Exception('Failed to load from backup API');
        }
      } catch (e) {
        // If both APIs fail, use backup rates
        setState(() {
          _errorMessage = 'Failed to fetch live rates. Using backup rates.';
          _isLoading = false;
          _exchangeRates = {
            'USD': 1.0,
            'EUR': 0.91,
            'INR': 82.5,
            'GBP': 0.79,
            'AUD': 1.52,
            'CAD': 1.35,
            'JPY': 148.5,
            'CNY': 7.23,
          };
        });
      }
    }
  }

  void _convertCurrency() {
    if (_amountController.text.isEmpty || _exchangeRates.isEmpty) return;

    final double? amount = double.tryParse(_amountController.text);
    if (amount == null) return;

    final double? fromRate = _exchangeRates[_fromCurrency];
    final double? toRate = _exchangeRates[_toCurrency];

    if (fromRate == null || toRate == null) return;

    setState(() {
      _convertedAmount = (amount / fromRate) * toRate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 30),

                // Animated Currency Icon with Gradient
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.tealAccent, Colors.teal],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(seconds: 1),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Icon(
                            Icons.currency_exchange,
                            size: 80,
                            color: Colors.black,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),

                const SizedBox(height: 30),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Enter Amount',
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon:
                        Icon(Icons.monetization_on, color: Colors.tealAccent),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDropdown(_fromCurrency, (val) {
                      if (val != null) {
                        setState(() {
                          _fromCurrency = val;
                        });
                      }
                    }),
                    IconButton(
                      icon: Icon(Icons.swap_horiz,
                          color: Colors.tealAccent, size: 40),
                      onPressed: () {
                        setState(() {
                          final temp = _fromCurrency;
                          _fromCurrency = _toCurrency;
                          _toCurrency = temp;
                          _convertCurrency();
                        });
                      },
                    ),
                    _buildDropdown(_toCurrency, (val) {
                      if (val != null) {
                        setState(() {
                          _toCurrency = val;
                        });
                      }
                    }),
                  ],
                ),
                const SizedBox(height: 20),

                // Animated Conversion Result
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [Colors.teal.withOpacity(0.3), Colors.black],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: _convertedAmount == null
                        ? Text(
                            '0.00 $_toCurrency',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.tealAccent,
                            ),
                          )
                        : Text(
                            '${_convertedAmount!.toStringAsFixed(2)} $_toCurrency',
                            key: ValueKey<double?>(_convertedAmount),
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.tealAccent,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _convertCurrency,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Convert', style: TextStyle(fontSize: 18)),
                ),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _fetchExchangeRates,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Refresh Rates', style: TextStyle(fontSize: 14)),
                ),

                const SizedBox(height: 30),

                // Live Rates Cards
                if (_isLoading)
                  CircularProgressIndicator()
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: _currencies.length,
                    itemBuilder: (context, index) {
                      final currency = _currencies[index];
                      final rate = _exchangeRates[currency];
                      if (rate == null) return SizedBox.shrink();

                      return Card(
                        elevation: 4,
                        color: Colors.teal.withOpacity(0.2),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                currency,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.tealAccent,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '1 USD = ${rate.toStringAsFixed(2)} $currency',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String value, Function(String?) onChanged) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: value,
        dropdownColor: Colors.black,
        style: const TextStyle(color: Colors.tealAccent, fontSize: 18),
        underline: Container(),
        onChanged: onChanged,
        items: _currencies.map((currency) {
          return DropdownMenuItem(
            value: currency,
            child: Text(currency),
          );
        }).toList(),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
