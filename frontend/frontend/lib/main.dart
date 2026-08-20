import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}

// =======================
// HALAMAN LOGIN (Custom API)
// =======================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController(text: "siswa@gmail.com");
  final passCtrl = TextEditingController(text: "123456");
  bool isLoading = false;

  Future<void> doLogin() async {
    if (emailCtrl.text.isEmpty || passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email dan Password tidak boleh kosong!")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final url = Uri.parse("http://localhost:2000/login");
      print("🔵 Mengirim login ke: $url");
      print("📤 Email: ${emailCtrl.text}, Password: ${passCtrl.text}");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": emailCtrl.text,
          "password": passCtrl.text,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException("Koneksi timeout - pastikan server berjalan!");
        },
      );

      print("✅ Response status: ${response.statusCode}");
      print("✅ Response body: ${response.body}");

      // Jangan cek mounted dulu, langsung print dulu
      if (response.statusCode == 200) {
        print("✅ Login BERHASIL!");
        
        // Navigasi langsung tanpa check mounted dulu
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        print("✅ Navigation berhasil dipanggil!");
      } else {
        print("❌ Status code bukan 200, Response: ${response.body}");
        
        // Try decode response
        try {
          final data = jsonDecode(response.body);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Login gagal! ${data['message'] ?? 'Cek email/password.'}"),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Login gagal! Status: ${response.statusCode}"),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } on TimeoutException catch (e) {
      print("❌ TIMEOUT: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on SocketException catch (e) {
      print("❌ SOCKET ERROR: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Tidak dapat terhubung ke server. Pastikan backend berjalan di port 2000!"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("❌ ERROR: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login Siswa"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(
                labelText: "Email",
              ),
            ),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : doLogin,
              child: isLoading
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text("Loading..."),
                      ],
                    )
                  : const Text("MASUK (Custom API)"),
            ),
          ],
        ),
      ),
    );
  }
}

// =======================
// HALAMAN HOME (Public API)
// =======================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String quote = "Tekan tombol di bawah untuk mengambil motivasi!";

  Future<void> fetchPublicQuote() async {
    final response = await http.get(
      Uri.parse("https://dummyjson.com/quotes/random"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        quote = "${data['quote']}\n\n- ${data['author']}";
      });
    } else {
      setState(() {
        quote = "Gagal mengambil data.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Motivasi Hari Ini"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                quote,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: fetchPublicQuote,
                child: const Text("Ambil Motivasi (Public API)"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}