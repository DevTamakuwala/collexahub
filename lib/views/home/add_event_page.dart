import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../models/event_model.dart';

class AddEventPage extends StatefulWidget {
  const AddEventPage({super.key});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _titleController = TextEditingController();
  final _descController = TextEditingController(); // Added
  final _venueController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _passLimitController = TextEditingController();

  String _selectedCategory = "Technical";
  String _hostingBranch = "MCA";
  bool _isOpenToAll = true;
  Uint8List? _selectedImageBytes;
  String? _fileName;
  bool _isUploading = false;

  // Cloudinary Config - REPLACED WITH YOUR DETAILS
  final String _cloudName = "de326hunc";
  final String _uploadPreset = "collexa_preset";

  final List<String> _branches = ["Computer Science", "MCA", "IT", "Mechanical", "Civil", "Electrical"];
  final List<String> _categories = ["Technical", "Cultural", "Sports", "Workshops"];

  Future<void> _pickImage() async {
    final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _fileName = image.name;
      });
    }
  }

  Future<void> _submitEvent() async {
    if (!_formKey.currentState!.validate() || _selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please add a poster and fill all fields")));
      return;
    }

    setState(() => _isUploading = true);

    try {
      var uri = Uri.parse("https://api.cloudinary.com/v1_1/$_cloudName/image/upload");
      var request = http.MultipartRequest("POST", uri);

      request.files.add(http.MultipartFile.fromBytes(
          'file',
          _selectedImageBytes!,
          filename: _fileName ?? "upload.jpg"
      ));

      request.fields['upload_preset'] = _uploadPreset;

      var response = await request.send();
      var resString = await response.stream.bytesToString();
      var jsonRes = jsonDecode(resString);

      // 👈 DEBUG INFO: This will tell you exactly what went wrong
      if (response.statusCode != 200) {
        print("Cloudinary Error Log: $jsonRes"); // Check your terminal for this!
        throw Exception(jsonRes['error']['message'] ?? "Upload failed");
      }

      String imageUrl = jsonRes['secure_url'];

      EventModel newEvent = EventModel(
        id: '',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        venue: _venueController.text.trim(),
        startDate: _startDateController.text.trim(),
        endDate: _endDateController.text.trim(),
        category: _selectedCategory,
        hostingBranch: _hostingBranch,
        imageUrl: imageUrl,
        passLimit: int.tryParse(_passLimitController.text) ?? 0,
        seatsFilled: 0,
        isOpenToAll: _isOpenToAll,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance.collection('events').add(newEvent.toMap());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Admin", style: TextStyle(fontWeight: FontWeight.bold))),
      body: _isUploading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPosterPicker(),
              _buildLabel("EVENT TITLE"),
              _buildInput(_titleController, "Event Name"),
              _buildLabel("DESCRIPTION"),
              _buildInput(_descController, "What is this event about?", maxLines: 3),
              Row(children: [
                // Change this line (116)
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel("START DATE"), _buildDateInput(_startDateController, "Start Date")])),
                const SizedBox(width: 15),
// And this line (118)
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel("END DATE"), _buildDateInput(_endDateController, "End Date")])),
                // Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel("END DATE"), _buildDateInput(_endDateController)])),
              ]),
              Row(children: [
                Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel("VENUE"), _buildInput(_venueController, "Venue")])),
                const SizedBox(width: 15),
                Expanded(flex: 1, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel("LIMIT"), _buildInput(_passLimitController, "Seats", isNumber: true)])),
              ]),
              _buildLabel("HOSTING BRANCH"),
              _buildDropdown(_hostingBranch, _branches, (v) => setState(() => _hostingBranch = v!)),
              _buildLabel("CATEGORY"),
              _buildDropdown(_selectedCategory, _categories, (v) => setState(() => _selectedCategory = v!)),
              SwitchListTile(title: const Text("Open to All Branches"), value: _isOpenToAll, onChanged: (v) => setState(() => _isOpenToAll = v)),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: _submitEvent, child: const Text("Publish Event"))),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widgets
  Widget _buildPosterPicker() => GestureDetector(
    onTap: _pickImage,
    child: Container(
      height: 180, width: double.infinity, margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
      child: _selectedImageBytes == null ? const Icon(Icons.add_a_photo, size: 40) : ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.memory(_selectedImageBytes!, fit: BoxFit.cover)),
    ),
  );

  Widget _buildInput(TextEditingController c, String h, {bool isNumber = false, int maxLines = 1}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15), margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(color: const Color(0xFFF1F3F6), borderRadius: BorderRadius.circular(12)),
    child: TextFormField(controller: c, maxLines: maxLines, keyboardType: isNumber ? TextInputType.number : TextInputType.text, decoration: InputDecoration(hintText: h, border: InputBorder.none), validator: (v) => v!.isEmpty ? "Required" : null),
  );

  Widget _buildDateInput(TextEditingController c, String h) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15), margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(color: const Color(0xFFF1F3F6), borderRadius: BorderRadius.circular(12)),
    child: TextFormField(controller: c, readOnly: true, decoration: InputDecoration(hintText: h, border: InputBorder.none, suffixIcon: const Icon(Icons.calendar_month)), onTap: () async {
      DateTime? d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
      if (d != null) setState(() => c.text = DateFormat('dd MMM, yyyy').format(d));
    }),
  );

  Widget _buildLabel(String t) => Padding(padding: const EdgeInsets.only(bottom: 5, top: 10), child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)));

  Widget _buildDropdown(String v, List<String> i, Function(String?) o) => Container(padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: const Color(0xFFF1F3F6), borderRadius: BorderRadius.circular(12)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: v, isExpanded: true, items: i.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: o)));
}