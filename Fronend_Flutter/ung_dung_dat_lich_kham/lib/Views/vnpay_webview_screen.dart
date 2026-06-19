import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VNPayWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  const VNPayWebViewScreen({super.key, required this.paymentUrl});

  @override
  State<VNPayWebViewScreen> createState() => _VNPayWebViewScreenState();
}

class _VNPayWebViewScreenState extends State<VNPayWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
          onNavigationRequest: (NavigationRequest request) {
            // 🌟 ĐOẠN XỬ LÝ QUAN TRỌNG: Kiểm tra xem VNPay đã redirect về trang kết quả chưa
            // Thay 'vnpay_return' bằng từ khóa trong returnUrl mà Backend của bạn cấu hình
            if (request.url.contains('vnpay_return')) { 
              
              // Kiểm tra xem trong link trả về có chữ thành công (vnp_ResponseCode=00) không
              if (request.url.contains('vnp_ResponseCode=00')) {
                Navigator.pop(context, 'SUCCESS'); // Trả về kết quả thành công cho màn hình trước
              } else {
                Navigator.pop(context, 'FAILED'); // Trả về thất bại
              }
              return NavigationDecision.prevent; // Chặn không cho webview load tiếp link đó nữa
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán VNPay', style: TextStyle(color: Colors.black, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context, 'CANCELLED'),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.blue)),
        ],
      ),
    );
  }
}