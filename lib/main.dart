import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MainApp());
}

class Contact {
  String name;
  // String name;dd
  String phone;
  File? image;

  Contact({required this.name, required this.phone, this.image});

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'imagePath': image?.path,
      };

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
        name: json['name'],
        phone: json['phone'],
        image: json['imagePath'] != null ? File(json['imagePath']) : null,
      );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.green,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Contact> contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contactList = contacts.map((c) => c.toJson()).toList();
    prefs.setString('contacts', jsonEncode(contactList));
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('contacts');
    if (data != null) {
      final List decoded = jsonDecode(data);
      setState(() {
        contacts = decoded.map((e) => Contact.fromJson(e)).toList();
      });
    }
  }

  void _addContact() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ContactForm()),
    );
    if (result != null && result is Contact) {
      setState(() {
        contacts.add(result);
      });
      _saveContacts();
    }
  }

  void _editContact(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContactForm(contact: contacts[index]),
      ),
    );
    if (result != null && result is Contact) {
      setState(() {
        contacts[index] = result;
      });
      _saveContacts();
    }
  }

  void _deleteContact(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Kişi Silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                contacts.removeAt(index);
              });
              _saveContacts();
              Navigator.pop(context);
            },
            child: const Text('Evet'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hayır'),
          ),
        ],
      ),
    );
  }

  void _callContact(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Easyphone'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Kişiler'),
              Tab(text: 'Acil Numaralar'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Kişiler sekmesi
            contacts.isEmpty
                ? const Center(child: Text('Kayıt yok.'))
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GridView.builder(
                      itemCount: contacts.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, index) {
                        final c = contacts[index];
                        return GestureDetector(
                          onDoubleTap: () => _callContact(c.phone),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 4,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: c.image != null
                                      ? Image.file(
                                          c.image!,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.person, size: 64),
                                        ),
                                ),
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 16,
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: Text(
                                      c.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 28,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 8,
                                            color: Colors.black,
                                            offset: Offset(1, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(24),
                                      onLongPress: () {
                                        showModalBottomSheet(
                                          context: context,
                                          builder: (_) => Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ListTile(
                                                leading: const Icon(Icons.edit),
                                                title: const Text('Düzenle'),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  _editContact(index);
                                                },
                                              ),
                                              ListTile(
                                                leading: const Icon(Icons.delete),
                                                title: const Text('Sil'),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  _deleteContact(index);
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      splashColor: Colors.black26,
                                      highlightColor: Colors.transparent,
                                      child: Container(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
            // Acil Numaralar sekmesi (şimdilik boş)
            const Center(child: Text('Acil Numaralar')),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addContact,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class ContactForm extends StatefulWidget {
  final Contact? contact;
  const ContactForm({this.contact, super.key});

  @override
  State<ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<ContactForm> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _phone;
  File? _image;

  @override
  void initState() {
    super.initState();
    _name = widget.contact?.name ?? '';
    _phone = widget.contact?.phone ?? '';
    _image = widget.contact?.image;
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.contact == null ? 'Kişi Ekle' : 'Kişi Düzenle')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: () async {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.photo),
                          title: const Text('Galeriden Seç'),
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.gallery);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: const Text('Kamera ile Çek'),
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.camera);
                          },
                        ),
                      ],
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 48,
                  backgroundImage: _image != null ? FileImage(_image!) : null,
                  child: _image == null ? const Icon(Icons.person, size: 48) : null,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'İsim'),
                validator: (v) => v == null || v.isEmpty ? 'İsim girin' : null,
                onSaved: (v) => _name = v!,
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _phone,
                decoration: const InputDecoration(labelText: 'Telefon'),
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.isEmpty ? 'Telefon girin' : null,
                onSaved: (v) => _phone = v!,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    Navigator.pop(context, Contact(name: _name, phone: _phone, image: _image));
                  }
                },
                child: Text(widget.contact == null ? 'Kaydet' : 'Güncelle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}