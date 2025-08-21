import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:logger/logger.dart';
import 'package:kazumi/utils/logger.dart';
import 'package:mobx/mobx.dart';
import 'package:kazumi/utils/storage.dart';
import 'package:hive/hive.dart';
import 'package:kazumi/utils/auto_updater.dart';

part 'my_controller.g.dart';

class MyController = _MyController with _$MyController;

abstract class _MyController with Store {
  Box setting = GStorage.setting;

  @observable
  ObservableList<String> shieldList = ObservableList.of([]);

  bool isDanmakuBlocked(String? danmaku) {
    if (danmaku == null || danmaku.isEmpty) return false;
    for (String item in shieldList) {
      if (item.isEmpty) continue;
      if (item.startsWith('/') && item.endsWith('/')) {
        if (item.length <= 2) continue;
        String pattern = item.substring(1, item.length - 1);
        try {
          if (RegExp(pattern).hasMatch(danmaku)) return true;
        } catch (_) {
          KazumiLogger().log(Level.error, '无效的弹幕屏蔽正则表达式: $pattern');
          continue;
        }
      } else {
        if (danmaku.contains(item)) return true;
      }
    }
    return false;
  }

  void loadShieldList() {
    shieldList.clear();
    shieldList.addAll(GStorage.shieldList.values.toList());
  }

  void addShieldList(String item) {
    if (item.isEmpty) {
      KazumiDialog.showToast(message: '请输入关键词');
      return;
    }
    if (item.length > 64) {
      KazumiDialog.showToast(message: '关键词过长');
      return;
    }
    if (shieldList.contains(item)) {
      KazumiDialog.showToast(message: '已存在该关键词');
      return;
    }
    shieldList.add(item);
    GStorage.shieldList.put(item, item);
    GStorage.shieldList.flush();
  }

  void removeShieldList(String item) {
    shieldList.remove(item);
    GStorage.shieldList.delete(item);
    GStorage.shieldList.flush();
  }

  Future<bool> checkUpdate({String type = 'manual'}) async {
    try {
      final autoUpdater = AutoUpdater();

      if (type == 'manual') {
        await autoUpdater.manualCheckForUpdates();
      } else {
        await autoUpdater.autoCheckForUpdates();
      }

      return true;
    } catch (err) {
      KazumiLogger().log(Level.error, '检查更新失败 ${err.toString()}');
      if (type == 'manual') {
        KazumiDialog.showToast(message: '检查更新失败，请稍后重试');
      }
      return false;
    }
  }
}
