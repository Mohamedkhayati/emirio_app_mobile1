import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/api/api_client.dart';
import '../core/constants/app_colors.dart';
import '../providers/cart_provider.dart';
import '../widgets/navbar.dart';
import 'dart:convert';
class CartCheckoutPage extends StatefulWidget {
  const CartCheckoutPage({super.key});

  @override
  State<CartCheckoutPage> createState() => _CartCheckoutPageState();
}

class _CartCheckoutPageState extends State<CartCheckoutPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();

  final _cardNameCtrl = TextEditingController();
  final _cardNumCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  final _d17PhoneCtrl = TextEditingController();
  final _d17RefCtrl = TextEditingController();
  final _bankRefCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String _paymentMethod = 'SIMULE';
  bool _acceptTerms = false;
  bool _submitting = false;
  Map<String, dynamic>? _successOrder;

  // Alert State
  String? _alertMessage;
  bool _isAlertError = true;

  // Signature State
  List<Offset?> _points = [];
  bool get _hasSignature => _points.where((p) => p != null).isNotEmpty;

  @override
  void initState() {
    super.initState();
    // Simulate loading user data 'me'
    _nomCtrl.text = 'Dupont';
    _prenomCtrl.text = 'Jean';
    context.read<CartProvider>().loadCart();
  }

  void _showAlert(String message, {bool isError = true}) {
    setState(() {
      _alertMessage = message;
      _isAlertError = isError;
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _alertMessage = null);
    });
  }

  void _clearSignature() {
    setState(() => _points.clear());
  }

  Future<void> _handleCheckout() async {
    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty) {
      _showAlert('Your cart is empty');
      return;
    }
    if (_nomCtrl.text.trim().isEmpty) return _showAlert('Please enter your last name');
    if (_prenomCtrl.text.trim().isEmpty) return _showAlert('Please enter your first name');
    if (_phoneCtrl.text.trim().isEmpty) return _showAlert('Please enter your phone number');
    if (_addressCtrl.text.trim().isEmpty) return _showAlert('Please enter your delivery address');
    if (_cityCtrl.text.trim().isEmpty) return _showAlert('Please enter your city');
    if (!_hasSignature) return _showAlert('Online signature is required');
    if (!_acceptTerms) return _showAlert('You must accept the invoice and order conditions');

    if (_paymentMethod == 'CARTE') {
      if (_cardNameCtrl.text.trim().isEmpty) return _showAlert('Please enter the name on the card');
      if (_cardNumCtrl.text.trim().isEmpty) return _showAlert('Please enter your card number');
      if (_expiryCtrl.text.trim().isEmpty) return _showAlert('Please enter the expiration date (MM/YY)');
      if (_cvvCtrl.text.trim().isEmpty) return _showAlert('Please enter the CVV code');
    }

    if (_paymentMethod == 'D17' && _d17PhoneCtrl.text.trim().isEmpty) return _showAlert('D17 phone number is required');
    if (_paymentMethod == 'VIREMENT' && _bankRefCtrl.text.trim().isEmpty) return _showAlert('Bank transfer reference is required');

    setState(() {
      _submitting = true;
      _successOrder = null;
    });

    try {
      // Create checkout payload mapping React object
      final payload = {
        'nom': _nomCtrl.text,
        'prenom': _prenomCtrl.text,
        'telephone': _phoneCtrl.text,
        'adresse': _addressCtrl.text,
        'ville': _cityCtrl.text,
        'codePostal': _postalCtrl.text,
        'modePaiement': _paymentMethod,
        'cardLast4': _paymentMethod == 'CARTE' ? _cardNumCtrl.text.replaceAll(' ', '').runes.toList().length > 4 ? _cardNumCtrl.text.substring(_cardNumCtrl.text.length - 4) : '' : '',
        'd17Phone': _paymentMethod == 'D17' ? _d17PhoneCtrl.text : '',
        'd17Reference': _paymentMethod == 'D17' ? _d17RefCtrl.text : '',
        'bankReference': _paymentMethod == 'VIREMENT' ? _bankRefCtrl.text : '',
        'note': _noteCtrl.text,
        'signatureDataUrl': 'base64:image/png', // Simplified for Flutter
        'acceptTerms': _acceptTerms,
      };

      final res = await ApiClient.post('/api/orders/checkout', payload);

      if (res.statusCode == 200 || res.statusCode == 201) {
        cart.clear();
        final data = jsonDecode(res.body);
        setState(() => _successOrder = data);
        _showAlert('Order created successfully! Redirecting...', isError: false);

        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) Navigator.pushReplacementNamed(context, '/orders'); // Navigate to Orders
        });
      } else {
        _showAlert('Checkout failed: ${res.body}');
      }
    } catch (e) {
      _showAlert('Checkout failed: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final double subtotal = cart.total;
    final double shipping = cart.items.isEmpty ? 0.0 : 4.0;
    final double total = subtotal + shipping;
    final bool isDesktop = MediaQuery.of(context).size.width > 920;

    return MainScaffold(
      currentIndex: 3,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: const Color(0xFF0F1014), // Dark background from CSS
            body: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 16, vertical: 32),
              child: isDesktop
                  ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 6, child: _buildCartPanel(cart)),
                const SizedBox(width: 24),
                Expanded(flex: 4, child: _buildPaymentPanel(subtotal, shipping, total)),
              ])
                  : Column(children: [
                _buildCartPanel(cart),
                const SizedBox(height: 24),
                _buildPaymentPanel(subtotal, shipping, total),
              ]),
            ),
          ),

          // Animated Alert
          if (_alertMessage != null)
            Positioned(
              top: 24,
              left: 16,
              right: 16,
              child: Align(
                alignment: Alignment.topCenter,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    constraints: const BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      color: const Color(0xEAE0F1014),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _isAlertError ? const Color(0xFFFF4D4F) : const Color(0xFF52C41A),
                        width: 2,
                      ),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 10))],
                    ),
                    child: Row(
                      children: [
                        Text(_isAlertError ? '⚠️' : '✅', style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 14),
                        Expanded(child: Text(_alertMessage!, style: const TextStyle(color: Colors.white, fontSize: 15))),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 20),
                          onPressed: () => setState(() => _alertMessage = null),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }

  // --- CART PANEL ---
  Widget _buildCartPanel(CartProvider cart) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF7F7FA), borderRadius: BorderRadius.circular(22)),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/catalog'),
                icon: const Icon(Icons.arrow_back, color: Color(0xFF20233A)),
                label: const Text('Shopping Continue', style: TextStyle(color: Color(0xFF20233A), fontWeight: FontWeight.bold)),
              ),
              if (cart.items.isNotEmpty)
                TextButton(
                  onPressed: cart.clear,
                  style: TextButton.styleFrom(backgroundColor: const Color(0xFFECECF6), foregroundColor: const Color(0xFF2C3152)),
                  child: const Text('Clear cart', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 18),
          const Text('Shopping cart', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E2238))),
          Text('You have ${cart.items.length} items in your cart', style: const TextStyle(color: Color(0xFF7B809C))),          const SizedBox(height: 24),

          if (cart.items.isEmpty)
            Container(
              padding: const EdgeInsets.all(34),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFD7D9EA), style: BorderStyle.solid)), // Note: Flutter doesn't natively do dashed easily without a package, using solid
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Text('Your cart is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2440))),
                  const SizedBox(height: 10),
                  const Text('Add products from the catalog to see them here.', style: TextStyle(color: Color(0xFF7F86A4))),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/catalog'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, // Simplified gradient
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Shop Now'),
                  )
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cart.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (_, i) {
                final item = cart.items[i];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFECECF4))),
                  child: Row(
                    children: [
                      Container(
                        width: 82, height: 82,
                        decoration: BoxDecoration(color: const Color(0xFFEEF1F7), borderRadius: BorderRadius.circular(14)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: CachedNetworkImage(
                            imageUrl: '${ApiClient.baseUrl}${item.product.imageUrl ?? ''}',
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const Center(child: Text('No image', style: TextStyle(fontSize: 12, color: Color(0xFF7B809C)))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.product.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2337))),
                            Text([item.selectedColor, item.selectedSize].where((e) => e != null).join(' • ').isEmpty ? 'Product option' : [item.selectedColor, item.selectedSize].where((e) => e != null).join(' • '), style: const TextStyle(color: Color(0xFF8A90AB), fontSize: 14)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(color: const Color(0xFFF3F4FB), borderRadius: BorderRadius.circular(30)),
                            child: Row(
                              children: [
                                IconButton(icon: const Icon(Icons.remove, size: 20), onPressed: () => cart.updateQuantity(item.id, item.quantity - 1), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 38, minHeight: 38)),
                                Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF202540))),
                                IconButton(icon: const Icon(Icons.add, size: 20), onPressed: () => cart.updateQuantity(item.id, item.quantity + 1), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 38, minHeight: 38)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 18),
                          SizedBox(
                            width: 80,
                            child: Text('${item.total.toStringAsFixed(3)} TND', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF282D4B))),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.grey),
                            onPressed: () => cart.removeFromCart(item.id),
                          )
                        ],
                      )
                    ],
                  ),
                );
              },
            )
        ],
      ),
    );
  }

  // --- PAYMENT PANEL ---
  Widget _buildPaymentPanel(double subtotal, double shipping, double total) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF5B5DD6), Color(0xFF5759D6)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x59251F7D), blurRadius: 60, offset: Offset(0, 24))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Checkout', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('Delivery, payment, invoice and signature', style: TextStyle(fontSize: 13, color: Colors.white70)),
                ],
              ),
              CircleAvatar(backgroundColor: Colors.white24, child: Text(_prenomCtrl.text.isNotEmpty ? _prenomCtrl.text[0].toUpperCase() : 'M', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 24),

          if (_successOrder != null)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: const Color(0x2953D8B7), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x5953D8B7))),
              child: Text(
                'Commande créée : ${_successOrder!['referenceCommande']}\nFacture : ${_successOrder!['invoiceNumber']}\nInstructions : ${_successOrder!['paymentInstructions']}',
                style: const TextStyle(color: Color(0xFFEAFFF7)),
              ),
            ),

          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Expanded(child: _buildField('Nom *', _nomCtrl)), const SizedBox(width: 12), Expanded(child: _buildField('Prénom *', _prenomCtrl))]),
                const SizedBox(height: 14),
                _buildField('Téléphone *', _phoneCtrl, placeholder: '+216 XX XXX XXX'),
                const SizedBox(height: 14),
                _buildField('Adresse *', _addressCtrl, placeholder: 'Rue, numéro...'),
                const SizedBox(height: 14),
                Row(children: [Expanded(child: _buildField('Ville *', _cityCtrl)), const SizedBox(width: 12), Expanded(child: _buildField('Code postal', _postalCtrl))]),
                const SizedBox(height: 14),

                _buildDropdown('Mode de paiement', _paymentMethod, [
                  {'val': 'CARTE', 'label': 'Carte bancaire'},
                  {'val': 'LIVRAISON', 'label': 'Paiement à la livraison'},
                  {'val': 'D17', 'label': 'Tunisia Poste D17'},
                  {'val': 'VIREMENT', 'label': 'Virement bancaire'},
                  {'val': 'SIMULE', 'label': '💳 Paiement simulé (démo)'},
                ], (v) => setState(() => _paymentMethod = v!)),

                const SizedBox(height: 14),

                if (_paymentMethod == 'SIMULE')
                  Container(
                    padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                    child: const Text('✅ Paiement simulé activé – Aucune information bancaire requise.', style: TextStyle(color: Colors.black87, fontSize: 13)),
                  ),

                if (_paymentMethod == 'CARTE') ...[
                  _buildField('Name on card *', _cardNameCtrl), const SizedBox(height: 14),
                  _buildField('Card Number *', _cardNumCtrl), const SizedBox(height: 14),
                  Row(children: [Expanded(child: _buildField('Expiration (MM/YY) *', _expiryCtrl)), const SizedBox(width: 12), Expanded(child: _buildField('CVV *', _cvvCtrl))]),
                  const SizedBox(height: 14),
                ],

                if (_paymentMethod == 'D17') ...[
                  _buildField('Numéro D17 *', _d17PhoneCtrl), const SizedBox(height: 14),
                  _buildField('Référence D17', _d17RefCtrl), const SizedBox(height: 14),
                ],

                if (_paymentMethod == 'VIREMENT') ...[
                  _buildField('Référence virement *', _bankRefCtrl), const SizedBox(height: 14),
                ],

                _buildField('Note', _noteCtrl, maxLines: 3),
                const SizedBox(height: 14),

                // Signature Box
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Signature en ligne *', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    TextButton(onPressed: _clearSignature, style: TextButton.styleFrom(foregroundColor: Colors.white), child: const Text('Effacer', style: TextStyle(fontSize: 12)))
                  ],
                ),
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: GestureDetector(
                    onPanUpdate: (DragUpdateDetails details) {
                      setState(() {
                        RenderBox object = context.findRenderObject() as RenderBox;
                        Offset _localPosition = object.globalToLocal(details.globalPosition);
                        // Offset adjustments to map to canvas properly
                        _points = List.from(_points)..add(details.localPosition);
                      });
                    },
                    onPanEnd: (DragEndDetails details) => _points.add(null),
                    child: CustomPaint(
                      painter: SignaturePainter(points: _points),
                      size: Size.infinite,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 24, width: 24, child: Checkbox(value: _acceptTerms, onChanged: (v) => setState(() => _acceptTerms = v!), fillColor: MaterialStateProperty.all(Colors.white), checkColor: Colors.black)),
                    const SizedBox(width: 10),
                    const Expanded(child: Text("J'accepte la facture proforma, le mode de paiement choisi et les conditions de commande. *", style: TextStyle(color: Colors.white, fontSize: 12))),
                  ],
                ),
                const SizedBox(height: 16),

                // Summary
                _buildSummaryRow('Subtotal', subtotal),
                _buildSummaryRow('Shipping', shipping),
                const Divider(color: Colors.white24, height: 24),
                _buildSummaryRow('Total', total, isTotal: true),
                const SizedBox(height: 16),

                // Checkout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: subtotal == 0 || _submitting ? null : _handleCheckout,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      backgroundColor: const Color(0xFF4FE0D2), // Gradient substitute
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_submitting ? "Processing..." : '${total.toStringAsFixed(3)} TND', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Text('Create order & invoice →', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, {String placeholder = '', int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white12,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        )
      ],
    );
  }

  Widget _buildDropdown(String label, String value, List<Map<String, String>> items, void Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: const Color(0xFF2D2F5E),
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              style: const TextStyle(color: Colors.white),
              onChanged: onChanged,
              items: items.map((i) => DropdownMenuItem(value: i['val'], child: Text(i['label']!))).toList(),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildSummaryRow(String label, double val, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white, fontSize: isTotal ? 18 : 14, fontWeight: isTotal ? FontWeight.bold : null)),
          Text('${val.toStringAsFixed(3)} TND', style: TextStyle(color: Colors.white, fontSize: isTotal ? 18 : 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// Simple Painter for the Canvas Signature
class SignaturePainter extends CustomPainter {
  List<Offset?> points;
  SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) => oldDelegate.points != points;
}