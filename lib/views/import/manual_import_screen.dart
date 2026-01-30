// Fill in the fields below and we will try and pinpoint it on the map."
// Field include "Name", "City", "Country", "Latitude", "Longitude"

import 'package:flutter/material.dart';
import 'package:away/services/api_service.dart';
import 'package:away/views/import/link_import_success_screen.dart';

class ManualImportScreen extends StatefulWidget {
  const ManualImportScreen({super.key});

  @override
  State<ManualImportScreen> createState() => _ManualImportScreenState();
}

class _ManualImportScreenState extends State<ManualImportScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityCountryController = TextEditingController();
  final _linkController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityCountryController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      final address =
          _addressController.text.trim().isNotEmpty
              ? _addressController.text.trim()
              : '${_nameController.text.trim()}, ${_cityCountryController.text.trim()}';

      // Geocode the address via backend
      try {
        final coords = await postToBackendForGeocoding(address);

        final manualPin = {
          'name': _nameController.text.trim(),
          'address': address,
          'city': _cityCountryController.text.trim(),
          'source': _linkController.text.trim(),
          'lat': coords['lat'],
          'lng': coords['lng'],
        };

        debugPrint("Manual pin with address: $manualPin");

        // Return to previous screen
        Navigator.pop(context, manualPin);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to geocode location. Please check the address or try again.',
            ),
          ),
        );
        return;
      }
    }
  }

  Future<Map<String, double>> postToBackendForGeocoding(String address) async {
    try {
      final data = await _api.geocodeAddress(
        address,
      ); // hits /api/geocode_address
      final lat = (data['lat'] as num?)?.toDouble();
      final lng = (data['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) {
        throw Exception('lat/lng missing in response');
      }
      return {'lat': lat, 'lng': lng};
    } catch (e) {
      debugPrint('❌ postToBackendForGeocoding error: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Import Manually")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                "Fill in the details to manually add a location.",
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Location Name",
                  border: OutlineInputBorder(),
                ),
                validator:
                    (val) =>
                        val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: "Address or Google Maps Link (optional)",
                  border: OutlineInputBorder(),
                ),
                validator: (val) => null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cityCountryController,
                decoration: const InputDecoration(
                  labelText: "City / Country",
                  border: OutlineInputBorder(),
                ),
                validator:
                    (val) =>
                        val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: "Source Link (optional)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _submitForm,
                icon: const Icon(Icons.check, size: 24, color: Colors.white),
                label: const Text("Save Location"),
                // This should then appear under the selected locations on the Import Success page, styled like the other location pins
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFF062D40),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
