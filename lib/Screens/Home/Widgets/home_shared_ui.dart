import 'package:cloud_app/Screens/Home/Widgets/avatar_widget.dart';
import 'package:cloud_app/Screens/Home/Widgets/file_item.dart';
import 'package:cloud_app/Screens/Home/Widgets/search_bar.dart';
import 'package:cloud_app/Screens/Home/Controller/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:primer_progress_bar/primer_progress_bar.dart';
import 'package:get/get.dart';

class HomeSharedUI extends StatefulWidget {
  final bool isMobile;

  const HomeSharedUI({super.key, required this.isMobile});

  @override
  State<HomeSharedUI> createState() => _HomeSharedUIState();
}

class _HomeSharedUIState extends State<HomeSharedUI> {
  final HomeController _homeController = Get.put(HomeController());
  late Searchbar _searchBar;

  @override
  void initState() {
    super.initState();
    _searchBar = Searchbar(onUpdate: () => setState(() {}));
  }

  @override
  void dispose() {
    _searchBar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.isMobile ? _buildMobileLayout() : _buildWebLayout();
  }

  // ==================== MOBILE LAYOUT ====================

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: _buildMobileAppBar(),
      drawer: _buildDrawer(),
      body: _buildFileSystemBody(),
    );
  }

  PreferredSizeWidget _buildMobileAppBar() {
    return AppBar(
      flexibleSpace: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 60.0, vertical: 5),
        child: _buildSearchBar(
          leading: const Icon(Icons.cloud, color: Colors.blue),
        ),
      ),
      actions: [_buildLogoutButton()],
      elevation: 1,
    );
  }

  // ==================== WEB LAYOUT ====================

  Widget _buildWebLayout() {
    return Row(
      children: [
        _buildDrawer(),
        Expanded(
          child: CustomScrollView(
            slivers: [_buildWebAppBar(), _buildFileSystemContent()],
          ),
        ),
      ],
    );
  }

  Widget _buildWebAppBar() {
    return SliverAppBar(
      pinned: true,
      leading: const Icon(Icons.cloud, color: Colors.blue),
      flexibleSpace: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 60.0, vertical: 5),
        child: Row(
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.35,
              child: _buildSearchBar(leading: const Icon(Icons.search)),
            ),
            const SizedBox(),
          ],
        ),
      ),
      actions: [_buildLogoutButton()],
      elevation: 1,
    );
  }

  // ==================== SHARED COMPONENTS ====================

  Widget _buildSearchBar({required Widget leading}) {
    return SearchBar(
      controller: _searchBar.searchController,
      hintText: 'Search files and folders...',
      leading: leading,
      trailing: _searchBar.query.isNotEmpty
          ? [
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _searchBar.clear,
              ),
            ]
          : null,
      shadowColor: WidgetStateColor.resolveWith((states) => Colors.transparent),
    );
  }

  Widget _buildLogoutButton() {
    return IconButton(
      icon: const Icon(Icons.logout),
      onPressed: _homeController.signOut,
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(),
          _buildStorageOverview(),
          _buildRecentUploads(),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return DrawerHeader(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _homeController.showProfileDialog,
            icon: Obx(
              () => AvatarWidget(
                imageUrl: _homeController.currentImageUrl,
                username: _homeController.currentUsername ?? '',
                radius: 40,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => Text(
              'Hello ${_homeController.currentUsername ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageOverview() {
    return Obx(() {
      final segments = _homeController.buildStorageSegments();

      if (segments.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(8),
          child: Text('No files uploaded yet'),
        );
      }

      return Padding(
        padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          decoration: _buildContainerDecoration(),
          child: Column(
            children: [
              const Text('Storage Overview'),
              const SizedBox(height: 8),
              PrimerProgressBar(segments: segments, maxTotalValue: 100),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildRecentUploads() {
    return Obx(() {
      final recentFiles = _homeController.getRecentUploads(limit: 3);

      if (recentFiles.isEmpty) {
        return const Text(
          'No recent uploads',
          style: TextStyle(color: Colors.grey),
        );
      }

      return Column(
        children: recentFiles.map<Widget>(_buildRecentFileItem).toList(),
      );
    });
  }

  Widget _buildRecentFileItem(FileItem file) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: _buildContainerDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getFileIcon(file), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(file.name, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _homeController.formatDate(file.updatedAt!),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildContainerDecoration() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      color: isDark ? Colors.grey[900] : Colors.white,
      border: Border.all(color: isDark ? Colors.blueGrey : Colors.white10),
    );
  }

  // ==================== FILE SYSTEM DISPLAY ====================

  Widget _buildFileSystemBody() {
    return Obx(() {
      if (_homeController.fileSystem == null) {
        return const Center(child: CircularProgressIndicator());
      }

      final items = _homeController.getFileItems(searchQuery: _searchBar.query);
      return items.isEmpty ? _buildEmptyState() : _buildFileList(items);
    });
  }

  Widget _buildFileSystemContent() {
    return Obx(() {
      if (_homeController.fileSystem == null) {
        return const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final items = _homeController.getFileItems(searchQuery: _searchBar.query);
      return items.isEmpty
          ? SliverFillRemaining(child: _buildEmptyState())
          : _buildSliverFileList(items);
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_open, size: 80),
          const SizedBox(height: 16),
          Text(
            _searchBar.query.isEmpty
                ? 'No files uploaded yet'
                : 'No results found',
            style: const TextStyle(fontSize: 18),
          ),
          if (_searchBar.query.isNotEmpty)
            TextButton(
              onPressed: _searchBar.clear,
              child: const Text('Clear search'),
            ),
        ],
      ),
    );
  }

  Widget _buildFileList(List<FileItem> items) {
    return ListView.builder(
      itemCount: items.length,
      padding: const EdgeInsets.only(bottom: 80),
      itemBuilder: (context, index) => _buildFileListItem(items[index]),
    );
  }

  Widget _buildSliverFileList(List<FileItem> items) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildFileListItem(items[index]),
        childCount: items.length,
      ),
    );
  }

  Widget _buildFileListItem(FileItem item) {
    return Padding(
      padding: EdgeInsets.only(left: item.depth * 16.0, top: 4, bottom: 4),
      child: ListTile(
        leading: Icon(
          _getItemIcon(item),
          color: item.isFolder ? Colors.blue : Colors.grey.shade700,
          size: 28,
        ),
        title: Text(item.name),
        subtitle: _buildFileSubtitle(item),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showItemOptions(item),
        ),
        onTap: () => _handleItemTap(item),
      ),
    );
  }

  Widget? _buildFileSubtitle(FileItem item) {
    if (!item.isFolder && item.updatedAt != null) {
      return Text(
        'Updated: ${_homeController.formatDate(item.updatedAt!)}',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      );
    }
    return null;
  }

  IconData _getItemIcon(FileItem item) {
    if (item.isFolder) {
      return _homeController.isFolderExpanded(item.fullPath)
          ? Icons.folder_open
          : Icons.folder;
    }
    return _getFileIcon(item);
  }

  void _handleItemTap(FileItem item) {
    if (item.isFolder) {
      setState(() => _homeController.toggleFolder(item.fullPath));
    } else {
      _homeController.showPreview(item);
    }
  }

  // ==================== FILE ICON HELPER (Using FileItem methods!) ====================

  IconData _getFileIcon(FileItem item) {
    if (item.isImageFile()) return Icons.image;
    if (item.extension == 'pdf') return Icons.picture_as_pdf;
    if (item.isDocumentFile()) return Icons.description;
    if (item.isVideoFile()) return Icons.video_file;
    if (item.isAudioFile()) return Icons.audio_file;
    if (item.isArchiveFile()) return Icons.folder_zip;

    return Icons.insert_drive_file;
  }

  // ==================== ITEM OPTIONS MENU ====================

  void _showItemOptions(FileItem item) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!item.isFolder) ...[
              _buildOptionTile(
                icon: Icons.preview,
                label: 'Preview',
                onTap: () {
                  Navigator.pop(context);
                  _homeController.showPreview(item);
                },
              ),
              _buildOptionTile(
                icon: Icons.download,
                label: 'Download',
                onTap: () {
                  Navigator.pop(context);
                  _homeController.downloadFile(item.fullPath, item.name);
                },
              ),
              _buildOptionTile(
                icon: Icons.share,
                label: 'Share',
                onTap: () {
                  Navigator.pop(context);
                  _homeController.shareLink(item.fullPath);
                },
              ),
            ],
            _buildOptionTile(
              icon: Icons.delete,
              label: 'Delete',
              iconColor: Colors.red,
              labelColor: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _homeController.confirmDelete(item);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    Color? labelColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(label, style: TextStyle(color: labelColor)),
      onTap: onTap,
    );
  }
}
