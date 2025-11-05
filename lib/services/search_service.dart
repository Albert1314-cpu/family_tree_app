import '../models/member.dart';
import '../models/family_tree.dart';

class SearchService {
  /// 搜索家族成员
  static List<Member> searchMembers({
    required List<Member> members,
    required String query,
  }) {
    if (query.isEmpty) {
      return members;
    }

    final lowerQuery = query.toLowerCase();
    return members.where((member) {
      // 按姓名搜索
      if (member.name.toLowerCase().contains(lowerQuery)) {
        return true;
      }
      
      // 按出生地搜索
      if (member.birthPlace != null && 
          member.birthPlace!.toLowerCase().contains(lowerQuery)) {
        return true;
      }
      
      // 按职业搜索
      if (member.occupation != null && 
          member.occupation!.toLowerCase().contains(lowerQuery)) {
        return true;
      }
      
      // 按备注搜索
      if (member.notes != null && 
          member.notes!.toLowerCase().contains(lowerQuery)) {
        return true;
      }
      
      return false;
    }).toList();
  }

  /// 搜索家族谱
  static List<FamilyTree> searchFamilyTrees({
    required List<FamilyTree> familyTrees,
    required String query,
  }) {
    if (query.isEmpty) {
      return familyTrees;
    }

    final lowerQuery = query.toLowerCase();
    return familyTrees.where((tree) {
      // 按名称搜索
      if (tree.name.toLowerCase().contains(lowerQuery)) {
        return true;
      }
      
      // 按备注搜索
      if (tree.notes != null && 
          tree.notes!.toLowerCase().contains(lowerQuery)) {
        return true;
      }
      
      return false;
    }).toList();
  }
}

