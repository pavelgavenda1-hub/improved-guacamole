import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:http/http.dart' as http;
import 'api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const GeoStoneApp());
}

class GeoStoneApp extends StatelessWidget {
  const GeoStoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeoStone',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool checking = true;
  bool authed = false;

  @override
  void initState() {
    super.initState();
    ApiClient.instance.fetchMe().then((value) {
      setState(() {
        authed = value != null;
        checking = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return authed ? const HomeShell() : const LoginScreen();
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GeoStone Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final token = await ApiClient.instance.login(emailCtrl.text, passCtrl.text);
                if (token == null) {
                  setState(() => error = 'Invalid credentials');
                } else {
                  if (!mounted) return;
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
                }
              },
              child: const Text('Login'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
              child: const Text('Register'),
            )
          ],
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final nickCtrl = TextEditingController();
  String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            TextField(controller: nickCtrl, decoration: const InputDecoration(labelText: 'Nickname')),
            if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final token = await ApiClient.instance
                    .register(emailCtrl.text, passCtrl.text, nickCtrl.text);
                if (token == null) {
                  setState(() => error = 'Registration failed');
                } else {
                  if (!mounted) return;
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
                }
              },
              child: const Text('Create account'),
            )
          ],
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  final pages = const [MapScreen(), MyStonesScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const QrScannerScreen())),
        child: const Icon(Icons.qr_code_scanner),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.brightness_low), label: 'My Stones'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class MapScreen extends HookWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stones = useState<List<dynamic>>([]);
    final controller = useState<GoogleMapController?>(null);

    useEffect(() {
      ApiClient.instance.listStones().then((value) => stones.value = value);
      return null;
    }, const []);

    final markers = stones.value
        .where((s) => s['latitude'] != null && s['longitude'] != null)
        .map<Marker>((s) => Marker(
              markerId: MarkerId(s['id']),
              position: LatLng(s['latitude'], s['longitude']),
              infoWindow: InfoWindow(
                  title: s['name'],
                  snippet: s['last_seen_at'] ?? '',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => StoneDetailScreen(stoneId: s['id'])))),
            ))
        .toSet();

    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(target: LatLng(0, 0), zoom: 1),
        onMapCreated: (c) => controller.value = c,
        markers: markers,
      ),
    );
  }
}

class MyStonesScreen extends HookWidget {
  const MyStonesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stones = useState<List<dynamic>>([]);

    useEffect(() {
      ApiClient.instance.listStones().then((value) {
        stones.value = value.where((s) => s['creator_user_id'] != null).toList();
      });
      return null;
    }, const []);

    return Scaffold(
      appBar: AppBar(title: const Text('My Stones')),
      body: ListView.builder(
        itemCount: stones.value.length,
        itemBuilder: (_, idx) {
          final s = stones.value[idx];
          return ListTile(
            title: Text(s['name'] ?? 'Unnamed'),
            subtitle: Text('QR: ${s['qr_token']}'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => StoneDetailScreen(stoneId: s['id'])),
            ),
          );
        },
      ),
    );
  }
}

class ProfileScreen extends HookWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = useState<Map<String, dynamic>?>(null);

    useEffect(() {
      ApiClient.instance.fetchMe().then((value) => data.value = value);
      return null;
    }, const []);

    if (data.value == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${data.value!['email']}'),
            Text('Nickname: ${data.value!['nickname']}'),
            Text('Stones created: ${data.value!['stones_created']}'),
            Text('Stones moved: ${data.value!['stones_moved']}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await ApiClient.instance.clearToken();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false);
                }
              },
              child: const Text('Logout'),
            )
          ],
        ),
      ),
    );
  }
}

class StoneDetailScreen extends HookWidget {
  final String stoneId;
  const StoneDetailScreen({super.key, required this.stoneId});

  @override
  Widget build(BuildContext context) {
    final stone = useState<Map<String, dynamic>?>(null);

    useEffect(() {
      ApiClient.instance.getStone(stoneId).then((value) => stone.value = value);
      return null;
    }, [stoneId]);

    if (stone.value == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final last = stone.value!['latest_location'];
    return Scaffold(
      appBar: AppBar(title: Text(stone.value!['name'] ?? 'Stone')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(stone.value!['description'] ?? ''),
            Text('Creator: ${stone.value!['creator_nickname'] ?? 'Unknown'}'),
            if (last != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text('Last location: ${last['latitude']}, ${last['longitude']}'),
                  if (last['photo_url'] != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Image.network('${ApiClient.instance.baseUrl.replaceFirst('/api', '')}${last['photo_url']}', height: 120),
                    ),
                ],
              ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => UpdateLocationScreen(stoneId: stoneId))),
              child: const Text('Add/Update Location'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => FullHistoryScreen(stoneId: stoneId))),
              child: const Text('Full history'),
            )
          ],
        ),
      ),
    );
  }
}

class FullHistoryScreen extends HookWidget {
  final String stoneId;
  const FullHistoryScreen({super.key, required this.stoneId});

  @override
  Widget build(BuildContext context) {
    final history = useState<List<dynamic>>([]);

    useEffect(() {
      ApiClient.instance
          .getStone(stoneId)
          .then((value) => history.value = (value?['recent_locations'] ?? []) as List<dynamic>);
      return null;
    }, [stoneId]);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: ListView.builder(
        itemCount: history.value.length,
        itemBuilder: (_, idx) {
          final h = history.value[idx];
          return ListTile(
            title: Text('${h['latitude']}, ${h['longitude']}'),
            subtitle: Text(h['note'] ?? ''),
          );
        },
      ),
    );
  }
}

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController ctrl) {
    controller = ctrl;
    controller?.scannedDataStream.listen((scanData) async {
      controller?.pauseCamera();
      final qrText = scanData.code ?? '';
      final token = qrText.split('/').last;
      final stone = await ApiClient.instance.stoneByToken(token);
      if (!mounted) return;
      if (stone == null) {
        Navigator.pop(context);
        return;
      }
      if (stone['is_active'] == false) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => ActivateStoneScreen(qrToken: token)));
      } else {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => StoneDetailScreen(stoneId: stone['id'])));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan stone')),
      body: QRView(
        key: qrKey,
        onQRViewCreated: _onQRViewCreated,
      ),
    );
  }
}

class ActivateStoneScreen extends StatefulWidget {
  final String qrToken;
  const ActivateStoneScreen({super.key, required this.qrToken});

  @override
  State<ActivateStoneScreen> createState() => _ActivateStoneScreenState();
}

class _ActivateStoneScreenState extends State<ActivateStoneScreen> {
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activate stone')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
            if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final stone = await ApiClient.instance
                    .activateStone(widget.qrToken, nameCtrl.text, descCtrl.text);
                if (stone == null) {
                  setState(() => error = 'Activation failed');
                } else {
                  if (!mounted) return;
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (_) => StoneDetailScreen(stoneId: stone['id'])));
                }
              },
              child: const Text('Activate'),
            )
          ],
        ),
      ),
    );
  }
}

class UpdateLocationScreen extends StatefulWidget {
  final String stoneId;
  const UpdateLocationScreen({super.key, required this.stoneId});

  @override
  State<UpdateLocationScreen> createState() => _UpdateLocationScreenState();
}

class _UpdateLocationScreenState extends State<UpdateLocationScreen> {
  Position? position;
  final noteCtrl = TextEditingController();
  XFile? photo;
  String status = 'Requesting location...';

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    final perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      setState(() => status = 'Location denied');
      return;
    }
    final pos = await Geolocator.getCurrentPosition();
    setState(() {
      position = pos;
      status = 'Ready to submit';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Location')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(status),
            TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Note')),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final picker = ImagePicker();
                final img = await picker.pickImage(source: ImageSource.camera);
                setState(() => photo = img);
              },
              child: const Text('Take photo'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: position == null
                  ? null
                  : () async {
                      final uri = Uri.parse('${ApiClient.instance.baseUrl}/stones/${widget.stoneId}/locations');
                      final request = http.MultipartRequest('POST', uri);
                      final token = await ApiClient.instance.getToken();
                      if (token != null) {
                        request.headers['Authorization'] = 'Bearer $token';
                      }
                      request.fields['latitude'] = position!.latitude.toString();
                      request.fields['longitude'] = position!.longitude.toString();
                      request.fields['note'] = noteCtrl.text;
                      if (photo != null) {
                        request.files.add(await http.MultipartFile.fromPath('photo', photo!.path));
                      }
                      final resp = await request.send();
                      if (!mounted) return;
                      if (resp.statusCode == 200) {
                        Navigator.of(context).pop();
                      } else {
                        setState(() => status = 'Failed to submit');
                      }
                    },
              child: const Text('Submit'),
            )
          ],
        ),
      ),
    );
  }
}
