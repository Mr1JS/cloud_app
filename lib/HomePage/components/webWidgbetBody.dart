import 'package:cloud_app/HomePage/components/avatarWidget.dart';
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
    return Obx(() {
      final currentImageUrl = homeController.currentImageUrl;
      final currentUsername = homeController.currentUsername;
      final fileSystem = homeController.fileSystem;

      return Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: Colors.lightBlueAccent,
            child: Column(
              children: [
                DrawerHeader(
                  child: Column(
                    children: [
                      IconButton(
                        onPressed: () => homeController.showProfileDialog(),
                        icon: AvatarWidget(
                          imageUrl: currentImageUrl,
                          username: currentUsername ?? '',
                          radius: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Hello ${currentUsername ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                ListTile(
                  title: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[100],
                        ),
                        child: Column(
                          children: [
                            const Text('Storage Overview'),
                            const SizedBox(height: 8),
                            PrimerProgressBar(
                              segments: [
                                Segment(
                                  color: Colors.red,
                                  value: 40,
                                  label: const Text('Images'),
                                  valueLabel: const Text("40%"),
                                ),
                                Segment(
                                  color: Colors.grey,
                                  value: 30,
                                  label: const Text('Text'),
                                  valueLabel: const Text("30%"),
                                ),
                                Segment(
                                  color: Colors.black,
                                  value: 30,
                                  label: const Text('Other'),
                                  valueLabel: const Text("30%"),
                                ),
                              ],
                              maxTotalValue: 100,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  title: Column(
                    children: [
                      const Text('Recent uploads'),
                      const SizedBox(height: 8),
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () {
                        homeController.signOut();
                      },
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: false,
                    titlePadding: const EdgeInsets.only(left: 16),
                    title: Row(
                      children: [
                        const Text(
                          'Cloud App',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(width: 32),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.4,
                          padding: const EdgeInsets.all(8.0),
                          child: SearchBar(
                            controller: searchBar.searchController,
                            hintText: 'Search files and folders...',
                            leading: const Icon(Icons.search),
                            trailing: searchBar.query.isNotEmpty
                                ? [
                                    IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () => searchBar.clear(),
                                    ),
                                  ]
                                : const [],
                            shadowColor: WidgetStateColor.resolveWith(
                              (states) => Colors.transparent,
                            ),
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (fileSystem == null) {
                        return SizedBox(
                          height: MediaQuery.of(context).size.height - 200,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final items = homeController.getFileItems(
                        searchQuery: searchBar.query,
                      );
                      if (index >= items.length) return null;

                      final item = items[index];

                      return Padding(
                        padding: EdgeInsets.only(left: item.depth * 20.0),
                        child: ListTile(
                          leading: Icon(
                            item.isFolder
                                ? (homeController.isFolderExpanded(
                                        item.fullPath,
                                      )
                                      ? Icons.folder_open
                                      : Icons.folder)
                                : Icons.insert_drive_file,
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name),
                              if (!item.isFolder && item.updatedAt != null)
                                Text(
                                  'Updated: ${homeController.formatDate(item.updatedAt!)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () => homeController.confirmDelete(item),
                          ),
                          onTap: () {
                            if (item.isFolder) {
                              setState(
                                () =>
                                    homeController.toggleFolder(item.fullPath),
                              );
                            } else {
                              homeController.showPreview(item);
                            }
                          },
                        ),
                      );
                    },
                    childCount: homeController
                        .getFileItems(searchQuery: searchBar.query)
                        .length,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}
