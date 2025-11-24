import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medicamento.dart';

class StorageService {
  static const String _keyMedicamentos = 'medicamentos';

  // Guardar lista de medicamentos
  Future<bool> guardarMedicamentos(List<Medicamento> medicamentos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> medicamentosJson =
          medicamentos.map((m) => m.toJson()).toList();
      final String jsonString = jsonEncode(medicamentosJson);
      return await prefs.setString(_keyMedicamentos, jsonString);
    } catch (e) {
      print('Error al guardar medicamentos: $e');
      return false;
    }
  }

  // Obtener lista de medicamentos
  Future<List<Medicamento>> obtenerMedicamentos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_keyMedicamentos);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Medicamento.fromJson(json)).toList();
    } catch (e) {
      print('Error al obtener medicamentos: $e');
      return [];
    }
  }

  // Agregar un nuevo medicamento
  Future<bool> agregarMedicamento(Medicamento medicamento) async {
    try {
      final medicamentos = await obtenerMedicamentos();
      medicamentos.add(medicamento);
      return await guardarMedicamentos(medicamentos);
    } catch (e) {
      print('Error al agregar medicamento: $e');
      return false;
    }
  }

  // Actualizar un medicamento existente
  Future<bool> actualizarMedicamento(Medicamento medicamento) async {
    try {
      final medicamentos = await obtenerMedicamentos();
      final index = medicamentos.indexWhere((m) => m.id == medicamento.id);
      
      if (index != -1) {
        medicamentos[index] = medicamento;
        return await guardarMedicamentos(medicamentos);
      }
      return false;
    } catch (e) {
      print('Error al actualizar medicamento: $e');
      return false;
    }
  }

  // Eliminar un medicamento
  Future<bool> eliminarMedicamento(String id) async {
    try {
      final medicamentos = await obtenerMedicamentos();
      medicamentos.removeWhere((m) => m.id == id);
      return await guardarMedicamentos(medicamentos);
    } catch (e) {
      print('Error al eliminar medicamento: $e');
      return false;
    }
  }

  // Limpiar todos los datos (útil para testing)
  Future<bool> limpiarTodo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_keyMedicamentos);
    } catch (e) {
      print('Error al limpiar datos: $e');
      return false;
    }
  }
}