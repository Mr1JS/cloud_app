import 'package:cloud_app/HomePage/components/avatarWidget.dart';
import 'package:cloud_app/HomePage/components/fileSystem.dart';
import 'package:cloud_app/HomePage/components/searchBar.dart';
import 'package:cloud_app/HomePage/controller/homeController.dart';
import 'package:flutter/material.dart';
import 'package:primer_progress_bar/primer_progress_bar.dart';
import 'package:get/get.dart';

class WebWidgetBody extends StatefulWidget {
  const WebWidgetBody({super.key});

  @override
  State<WebWidgetBody> createState() => WebWidgetBodyState();
}

class WebWidgetBodyState extends State<WebWidgetBody> {
  final HomeController homeController = Get.find<HomeController>();
  final SearchController searchController = SearchController();
  late Searchbar searchBar;

  @override
  void initState() {
    super.initState();
    searchBar = Searchbar(
      onUpdate: () {
        setState(() {});
      },
    );
  }

  @override
  void dispose() {
    searchBar.dispose();
    super.dispose();
  }
  /* 
  // Only local function left - refreshFiles for setState
  void refreshFiles() {
    if (mounted) {
      setState(() {});
    }
  } */

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Drawer(
          child: Column(
            children: [
              DrawerHeader(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => homeController.showProfileDialog(),
                      icon: Obx(
                        () => AvatarWidget(
                          imageUrl: homeController.currentImageUrl,
                          username: homeController.currentUsername ?? '',
                          radius: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Hello ${homeController.currentUsername ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Storage Overview
              Obx(() {
                final segments = homeController.buildStorageSegments();

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
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[900]
                          : Colors.white,
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.blueGrey
                            : Colors.white10,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text('Storage Overview'),
                        const SizedBox(height: 8),
                        PrimerProgressBar(
                          segments: segments,
                          maxTotalValue: 100,
                        ),
                      ],
                    ),
                  ),
                );
              }),
              Obx(() {
                final recentFiles = homeController.getRecentUploads(limit: 3);

                if (recentFiles.isEmpty) {
                  return const Text(
                    'No recent uploads',
                    style: TextStyle(color: Colors.grey),
                  );
                }

                return Column(
                  children: recentFiles.map((file) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[900]
                              : Colors.white,
                          border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.blueGrey
                                : Colors.white10,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(_getFileIcon(file.name), size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    file.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            Text(
                              homeController.formatDate(file.updatedAt!),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),

              // Storage Overview
            ],
          ),
        ),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                leading: Icon(Icons.cloud, color: Colors.blue),
                flexibleSpace: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 60.0,
                    vertical: 5,
                  ),

                  child: Row(
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.35,
                        child: SearchBar(
                          controller: searchBar.searchController,
                          hintText: 'Search files and folders...',
                          leading: Icon(Icons.search),
                          trailing: searchBar.query.isNotEmpty
                              ? [
                                  IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () => searchBar.clear(),
                                  ),
                                ]
                              : null,
                          shadowColor: WidgetStateColor.resolveWith(
                            (states) => Colors.transparent,
                          ),
                        ),
                      ),
                      SizedBox(),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () {
                      homeController.signOut();
                    },
                  ),
                ],
                elevation: 1,
              ),

              // Your reactive body
              Obx(() {
                final fileSystem = homeController.fileSystem;

                if (fileSystem == null) {
                  // Sliver for loading state
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final items = homeController.getFileItems(
                  searchQuery: searchBar.query,
                );

                if (items.isEmpty) {
                  // Sliver for empty state
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open, size: 80),
                          const SizedBox(height: 16),
                          Text(
                            searchBar.query.isEmpty
                                ? 'No files uploaded yet'
                                : 'No results found',
                            style: TextStyle(fontSize: 18),
                          ),
                          if (searchBar.query.isNotEmpty)
                            TextButton(
                              onPressed: () => searchBar.clear(),
                              child: const Text('Clear search'),
                            ),
                        ],
                      ),
                    ),
                  );
                }

                // Sliver for the list of items
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = items[index];

                    return Padding(
                      padding: EdgeInsets.only(
                        left: item.depth * 16.0,
                        top: 4,
                        bottom: 4,
                      ),
                      child: ListTile(
                        leading: Icon(
                          item.isFolder
                              ? (homeController.isFolderExpanded(item.fullPath)
                                    ? Icons.folder_open
                                    : Icons.folder)
                              : _getFileIcon(item.name),
                          color: item.isFolder
                              ? Colors.blue
                              : Colors.grey.shade700,
                          size: 28,
                        ),
                        title: Text(item.name),
                        subtitle: !item.isFolder && item.updatedAt != null
                            ? Text(
                                'Updated: ${homeController.formatDate(item.updatedAt!)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              )
                            : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () => _showItemOptions(context, item),
                        ),
                        onTap: () {
                          if (item.isFolder) {
                            setState(
                              () => homeController.toggleFolder(item.fullPath),
                            );
                          } else {
                            homeController.showPreview(item);
                          }
                        },
                      ),
                    );
                  }, childCount: items.length),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext)) {
      return Icons.image;
    } else if (['pdf'].contains(ext)) {
      return Icons.picture_as_pdf;
    } else if (['doc', 'docx'].contains(ext)) {
      return Icons.description;
    } else if (['mp4', 'mov', 'avi', 'mkv'].contains(ext)) {
      return Icons.video_file;
    } else if (['mp3', 'wav', 'aac'].contains(ext)) {
      return Icons.audio_file;
    } else if (['zip', 'rar', '7z'].contains(ext)) {
      return Icons.folder_zip;
    } else {
      return Icons.insert_drive_file;
    }
  }

  void _showItemOptions(BuildContext context, FileItem item) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!item.isFolder)
                ListTile(
                  leading: const Icon(Icons.preview),
                  title: const Text('Preview'),
                  onTap: () {
                    Navigator.pop(context);
                    if (!item.isFolder) {
                      homeController.showPreview(item);
                    }
                  },
                ),
              if (!item.isFolder)
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Download'),
                  onTap: () {
                    Navigator.pop(context);
                    // Add download functionality here
                    homeController.downloadFile(item.fullPath, item.name);
                  },
                ),
              if (!item.isFolder)
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('Share'),
                  onTap: () {
                    Navigator.pop(context);
                    // Add share functionality here
                    homeController.shareLink(item.fullPath);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  homeController.confirmDelete(item);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
