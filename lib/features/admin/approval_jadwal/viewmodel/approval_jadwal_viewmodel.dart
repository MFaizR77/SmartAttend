import 'package:flutter/foundation.dart';
import '../../../../../data/remote/database_service.dart';

class ApprovalJadwalViewModel extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  
  bool isLoading = false;
  String? errorMessage;
  
  List<Map<String, dynamic>> daftarPengajuan = [];
  
  Future<void> loadPengajuan() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      daftarPengajuan = await _db.getAllPengajuan();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> prosesPengajuan(dynamic id, String status) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _db.updateStatusPengajuan(id, status);
      await loadPengajuan(); // reload setelah update
      return true;
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
