import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:file_picker/file_picker.dart';

import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/services.dart';
import 'google_drive_service.dart';
import 'youtube_service.dart';
import 'newsletter_preview_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();

  static MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>()!;
}

class MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void changeTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Generador de Newsletter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      themeMode: _themeMode,
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
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: [
    'https://www.googleapis.com/auth/drive',
    'https://www.googleapis.com/auth/youtube.upload',
  ]);
  GoogleSignInAccount? _currentUser;
  GoogleDriveService? _driveService;
  YouTubeService? _youTubeService;
  List<drive.File> _folders = [];
  drive.File? _selectedFolder;

  PlatformFile? _selectedVideo;

  final HtmlEditorController introController1 = HtmlEditorController();
  final HtmlEditorController introController2 = HtmlEditorController();

  final _newFolderNameController = TextEditingController();

  final Map<String, PlatformFile?> _selectedFiles = {};

  List<Section> _sections = [];

  Color _backgroundColor = Colors.white;
  Color _titleColor = Colors.blue;
  Color _paragraphColor = Colors.black;
  Color _buttonColor = Colors.blue;
  Color _buttonTextColor = Colors.white;

  final _pageTitleController = TextEditingController(text: 'Newsletter CITED Cantabria');
  final _headerLinkController = TextEditingController(text: 'https://educantabria.es/web/cited');
  final _headerLogoUrlController = TextEditingController(text: 'https://www.educantabria.es/documents/21790824/0/Logo+Cited_Aula+del+futuro+%281%29.png');
  final _bannerLinkController = TextEditingController(text: 'https://educantabria.es/web/cited');
  final _bannerImgUrlController = TextEditingController(text: 'https://www.educantabria.es/documents/21790824/21790904/artificial-intelligence-3706562_1920.jpg');
  final _bannerImgAltController = TextEditingController(text: 'Innovación y Formación CITED');
  final _introTitleController = TextEditingController(text: 'Descubre el CITED: Tu Futuro Empieza Aquí');
  final _videoTitleController = TextEditingController(text: 'Conoce el CITED en 1 Minuto');
  final _videoParagraphController = TextEditingController(text: 'Descubre nuestras instalaciones y todo lo que podemos ofrecerte en este breve video.');
  final _videoLinkController = TextEditingController(text: 'https://www.educantabria.es/documents/21790824/21790889/Bienvenid%40s+al+CITED.mp4');
  final _videoThumbnailUrlController = TextEditingController(text: 'https://www.educantabria.es/documents/21790824/21790904/video.png');
  final _videoThumbnailAltController = TextEditingController(text: 'Ver video sobre el CITED');
  final _footerLinkController = TextEditingController(text: 'https://educantabria.es/web/cited');
  final _footerLinkTextController = TextEditingController(text: 'educantabria.es/web/cited');

  @override
  void initState() {
    super.initState();
    _initializeSections();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {      
      setState(() {
        _currentUser = account;
        if (_currentUser != null) {
          _driveService = GoogleDriveService(_currentUser!);
          _youTubeService = YouTubeService(_currentUser!);
          _loadFolders();
        }
      });
    });
    _googleSignIn.signInSilently();
  }

  @override
  void dispose() {
    _newFolderNameController.dispose();
    _pageTitleController.dispose();
    _headerLinkController.dispose();
    _headerLogoUrlController.dispose();
    _bannerLinkController.dispose();
    _bannerImgUrlController.dispose();
    _bannerImgAltController.dispose();
    _introTitleController.dispose();
    _videoTitleController.dispose();
    _videoParagraphController.dispose();
    _videoLinkController.dispose();
    _videoThumbnailUrlController.dispose();
    _videoThumbnailAltController.dispose();
    _footerLinkController.dispose();
    _footerLinkTextController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      debugPrint("Error signing in: $error");
    }
  }

  void _initializeSections() {
    _sections = [      
      Section(
        imgSrc: 'https://www.educantabria.es/documents/21790824/21790904/formacion.png',
        imgAlt: 'Formación para Docentes',
        title: 'Formación del Profesorado',
        paragraph: 'Actualiza tus competencias digitales, descubre metodologías activas y lidera el cambio en tu aula. Ofrecemos cursos prácticos, píldoras formativas y asesoramiento en proyectos de innovación.',
        buttonLink: 'https://aulacited.educantabria.es',
        buttonText: 'Ver Cursos para Docentes',
      ),
      Section(
        imgSrc: 'https://www.educantabria.es/documents/21790824/21790904/programas.png',
        imgAlt: 'Programas CITED',
        title: 'Nuestros Programas',
        paragraph: 'Descubre los programas de innovación que impulsamos desde el CITED, diseñados para fomentar la integración de la tecnología y las nuevas metodologías en los centros educativos de Cantabria.',
        buttonLink: 'https://www.educantabria.es/web/cited/programas1',
        buttonText: 'Ver Todos los Programas',
      ),
    ];
  }

  void _addSection() {
    setState(() {
      _sections.add(Section(title: 'Nueva Sección'));
    });
  }

  void _removeSection(int index) {
    setState(() {
      _sections.removeAt(index);
    });
  }

  void _updateUrlForLabel(String label, String url) {
    setState(() {
      if (label == 'Logo (Cabecera)') {
        _headerLogoUrlController.text = url;
      } else if (label == 'Banner Principal') {
        _bannerImgUrlController.text = url;
      } else if (label == 'Miniatura Vídeo') {
        _videoThumbnailUrlController.text = url;
      } else if (label.startsWith('Imagen (Sección ')) {
        final sectionNumberString = label.replaceAll(RegExp(r'[^0-9]'), '');
        try {
          final sectionNumber = int.parse(sectionNumberString);
          final sectionIndex = sectionNumber - 1;
          if (sectionIndex >= 0 && sectionIndex < _sections.length) {
            _sections[sectionIndex].imgSrcController.text = url;
          }
        } catch (e) {
          // Ignorar si el parseo falla
        }
      }
    });
  }

  Future<void> _handleSignOut() => _googleSignIn.disconnect();

  Future<void> _loadFolders() async {
    if (_driveService == null) return;
    final folders = await _driveService!.listFolders();
    if (!mounted) return;
    setState(() {
      _folders = folders;
    });
  }

  Future<void> _loadImagesInFolder() async {
    if (_driveService == null || _selectedFolder == null || _selectedFolder!.id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona una carpeta primero')),
        );
      }
      return;
    }
    
    try {
      final images = await _driveService!.listImagesInFolder(_selectedFolder!.id!);
      if (mounted) {
        _showImagesDialog(images);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando imágenes: $e')),
        );
      }
    }
  }

  void _showImagesDialog(List<DriveImage> images) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Imágenes en la Carpeta'),
          content: SizedBox(
            width: double.maxFinite,
            child: images.isEmpty 
              ? const Text('No hay imágenes en esta carpeta')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: images.length,
                  itemBuilder: (BuildContext context, int index) {
                    final image = images[index];
                    return ListTile(
                      leading: Image.network(
                        image.url,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.broken_image);
                        },
                      ),
                      title: Text(image.name),
                      subtitle: Text(
                        image.url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: image.url));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('URL copiada')),
                          );
                        },
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
          ),
          actions: [
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generador de Newsletter'),
        actions: <Widget>[
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              MyApp.of(context).changeTheme(
                  isDarkMode ? ThemeMode.light : ThemeMode.dark);
            },
          ),
          if (_currentUser != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _handleSignOut,
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Generador de Contenido para Newsletter',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _ResourceUploaderCard(
              currentUser: _currentUser,
              sections: _sections,
              driveService: _driveService,
              youTubeService: _youTubeService,
              folders: _folders,
              selectedFolder: _selectedFolder,
              newFolderNameController: _newFolderNameController,
              selectedFiles: _selectedFiles,
              selectedVideo: _selectedVideo,
              onSignIn: _handleSignIn,
              videoTitleController: _videoTitleController,
              videoParagraphController: _videoParagraphController,
              videoLinkController: _videoLinkController,
              onLoadFolders: _loadFolders,
              onLoadImages: _loadImagesInFolder,
              onFolderSelected: (folder) => setState(() => _selectedFolder = folder),
              onFileSelected: (label, file) { setState(() => _selectedFiles[label] = file); },
              onVideoSelected: (file) => setState(() => _selectedVideo = file),
              onUrlReceived: (label, url) {
                _updateUrlForLabel(label, url);
              },
              headerLogoUrlController: _headerLogoUrlController,
              bannerImgUrlController: _bannerImgUrlController,
              videoThumbnailUrlController: _videoThumbnailUrlController,
              onFilesUploaded: () => setState(() => _selectedFiles.clear()),
            ),
            const SizedBox(height: 16),
            _HeaderBannerCard(
              pageTitleController: _pageTitleController,
              headerLinkController: _headerLinkController,
              headerLogoUrlController: _headerLogoUrlController,
              bannerLinkController: _bannerLinkController,
              bannerImgUrlController: _bannerImgUrlController,
              bannerImgAltController: _bannerImgAltController,
            ),
            const SizedBox(height: 16),
            _IntroContentCard(
              introTitleController: _introTitleController,
              introController1: introController1,
              introController2: introController2,
            ),
            const SizedBox(height: 16),
            _DynamicSectionsManager(
              sections: _sections,
              onAddSection: _addSection,
              onRemoveSection: _removeSection,
              isDarkMode: isDarkMode,
              driveService: _driveService,
              selectedFolder: _selectedFolder,
            ),
            const SizedBox(height: 16),
            _VideoSectionCard(
              youTubeService: _youTubeService,
              selectedVideo: _selectedVideo,
              onVideoSelected: (file) => setState(() => _selectedVideo = file),
              videoTitleController: _videoTitleController,
              videoParagraphController: _videoParagraphController,
              videoLinkController: _videoLinkController,
              videoThumbnailUrlController: _videoThumbnailUrlController,
              videoThumbnailAltController: _videoThumbnailAltController,
            ),
            const SizedBox(height: 16),
            _StylesCard(
              backgroundColor: _backgroundColor,
              titleColor: _titleColor,
              paragraphColor: _paragraphColor,
              buttonColor: _buttonColor,
              buttonTextColor: _buttonTextColor,
              onBackgroundColorChanged: (color) => setState(() => _backgroundColor = color),
              onTitleColorChanged: (color) => setState(() => _titleColor = color),
              onParagraphColorChanged: (color) => setState(() => _paragraphColor = color),
              onButtonColorChanged: (color) => setState(() => _buttonColor = color),
              onButtonTextColorChanged: (color) => setState(() => _buttonTextColor = color),
            ),
            const SizedBox(height: 16),
            _FooterCard(
              footerLinkController: _footerLinkController,
              footerLinkTextController: _footerLinkTextController,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                final template = await rootBundle.loadString('newsletter_template.html');
                final intro1 = await introController1.getText();
                final intro2 = await introController2.getText();

                final titleHexColor = '#${_titleColor.value.toRadixString(16).padLeft(8, '0').substring(2)}';
                final paragraphHexColor = '#${_paragraphColor.value.toRadixString(16).padLeft(8, '0').substring(2)}';
                final buttonHexColor = '#${_buttonColor.value.toRadixString(16).padLeft(8, '0').substring(2)}';
                final buttonTextHexColor = '#${_buttonTextColor.value.toRadixString(16).padLeft(8, '0').substring(2)}';
                final backgroundColor = '#${_backgroundColor.value.toRadixString(16).padLeft(8, '0').substring(2)}';

                String sectionsHtml = '';
                for (var section in _sections) {
                  final sectionParagraph = await section.paragraphController.getText();
                  sectionsHtml += '''
                    <!-- Sección ${_sections.indexOf(section) + 1} -->
                    <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 40px; background-color: #ffffff;">
                      <tr>
                        <td align="center" style="padding: 30px 0 20px 0;">
                          <table width="560" border="0" cellspacing="0" cellpadding="0" style="margin: 0 auto;">
                            <tr>
                              <td align="center">
                                <img src="${section.imgSrcController.text}" alt="${section.imgAltController.text}" style="width: 500px; height: 280px; object-fit: cover; display: block; margin: 0 auto; border: 0;">
                              </td>
                            </tr>
                          </table>
                        </td>
                      </tr>
                      <tr>
                        <td align="center" style="padding: 10px 0;">
                          <table width="560" border="0" cellspacing="0" cellpadding="0" style="margin: 0 auto;">
                            <tr>
                              <td align="center">
                                <h2 style="color: $titleHexColor; font-size: 24px; font-family: Arial, sans-serif; margin: 0; padding: 0; line-height: 1.3;">${section.titleController.text}</h2>
                              </td>
                            </tr>
                          </table>
                        </td>
                      </tr>
                      <tr>
                        <td align="center" style="padding: 20px 0;">
                          <table width="560" border="0" cellspacing="0" cellpadding="0" style="margin: 0 auto;">
                            <tr>
                              <td align="center" style="padding: 0 20px;">
                                <div style="color: $paragraphHexColor; font-size: 16px; font-family: Arial, sans-serif; line-height: 1.6; text-align: center; max-width: 520px;">$sectionParagraph</div>
                              </td>
                            </tr>
                          </table>
                        </td>
                      </tr>
                      <tr>
                        <td align="center" style="padding: 25px 0 30px 0;">
                          <table border="0" cellspacing="0" cellpadding="0" style="margin: 0 auto;">
                            <tr>
                              <td align="center" style="border-radius: 5px; background-color: $buttonHexColor;">
                                <a href="${section.buttonLinkController.text}" target="_blank" style="background-color: $buttonHexColor; color: $buttonTextHexColor; padding: 14px 35px; font-size: 16px; font-weight: bold; text-decoration: none; border-radius: 5px; display: inline-block; font-family: Arial, sans-serif; line-height: 1.5;">${section.buttonTextController.text}</a>
                              </td>
                            </tr>
                          </table>
                        </td>
                      </tr>
                    </table>
                  ''';
                }

                final Map<String, String> replacements = {
                  '{{PAGE_TITLE}}': _pageTitleController.text,
                  '{{HEADER_LINK}}': _headerLinkController.text,
                  '{{HEADER_LOGO_URL}}': _headerLogoUrlController.text,
                  '{{HEADER_LOGO_ALT}}': 'Logo CITED',
                  '{{BANNER_LINK}}': _bannerLinkController.text,
                  '{{BANNER_IMG_URL}}': _bannerImgUrlController.text,
                  '{{BANNER_IMG_ALT}}': _bannerImgAltController.text,
                  '{{INTRO_TITLE}}': _introTitleController.text,
                  '{{INTRO_P1}}': intro1,
                  '{{INTRO_P2}}': intro2,
                  '{{SECTIONS}}': sectionsHtml,
                  '{{VIDEO_TITLE}}': _videoTitleController.text,
                  '{{VIDEO_PARAGRAPH}}': _videoParagraphController.text,
                  '{{VIDEO_LINK}}': _videoLinkController.text,
                  '{{VIDEO_THUMBNAIL_URL}}': _videoThumbnailUrlController.text, 
                  '{{VIDEO_THUMBNAIL_ALT}}': _videoThumbnailAltController.text,
                  '{{YEAR}}': DateTime.now().year.toString(),
                  '{{FOOTER_LINK}}': _footerLinkController.text,
                  '{{FOOTER_LINK_TEXT}}': _footerLinkTextController.text,
                  '{{BACKGROUND_COLOR}}': backgroundColor,
                  '{{TITLE_COLOR}}': titleHexColor,
                  '{{PARAGRAPH_COLOR}}': paragraphHexColor,
                  '{{BUTTON_COLOR}}': buttonHexColor,
                  '{{BUTTON_TEXT_COLOR}}': buttonTextHexColor,
                };

                String output = template;
                replacements.forEach((key, value) {
                  output = output.replaceAll(key, value);
                });
                
                if (!mounted) return;
                
                
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NewsletterPreviewScreen(htmlContent: output),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16.0),
              ),
              child: const Text('Generar Newsletter', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

// ... [El resto de los widgets (_ResourceUploaderCard, _HeaderBannerCard, etc.) se mantienen igual que en el código anterior]
// Solo necesitas actualizar la parte del HTML generation

// --- Widgets Refactorizados ---

class _ResourceUploaderCard extends StatelessWidget {
  final GoogleSignInAccount? currentUser;
  final List<Section> sections;
  final GoogleDriveService? driveService;
  final YouTubeService? youTubeService;
  final List<drive.File> folders;
  final drive.File? selectedFolder;
  final TextEditingController newFolderNameController;
  final Map<String, PlatformFile?> selectedFiles;
  final PlatformFile? selectedVideo;
  final VoidCallback onSignIn;
  final TextEditingController videoTitleController;
  final TextEditingController videoParagraphController;
  final TextEditingController videoLinkController;
  final Future<void> Function() onLoadFolders;
  final Future<void> Function() onLoadImages;
  final ValueChanged<drive.File?> onFolderSelected;
  final Function(String, PlatformFile) onFileSelected;
  final Function(PlatformFile) onVideoSelected;
  final Function(String, String) onUrlReceived;
  final TextEditingController headerLogoUrlController;
  final TextEditingController bannerImgUrlController;
  final TextEditingController videoThumbnailUrlController;
  final VoidCallback onFilesUploaded;

  const _ResourceUploaderCard({
    required this.currentUser, 
    required this.sections, 
    required this.driveService, 
    required this.youTubeService,
    required this.folders,
    required this.selectedFolder, 
    required this.newFolderNameController,
    required this.selectedFiles,
    required this.onUrlReceived,
    required this.videoTitleController,
    required this.videoParagraphController,
    required this.videoLinkController,
    required this.selectedVideo, 
    required this.onSignIn,
    required this.onLoadFolders,
    required this.onLoadImages,
    required this.onFolderSelected,
    required this.onFileSelected,
    required this.onVideoSelected,
    required this.headerLogoUrlController,
    required this.bannerImgUrlController,
    required this.videoThumbnailUrlController,
    required this.onFilesUploaded,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Subida de Recursos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (currentUser == null) ...[
              const Text(
                  'Para subir tus imágenes y vídeos, primero necesitas conectar tu cuenta de Google.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onSignIn,
                child: const Text('Conectar con Google'),
              ),
              const SizedBox(height: 16),
              const Text('Estado: No conectado',
                  style: TextStyle(color: Colors.red)),
            ] else ...[
              Text('Conectado como: ${currentUser!.displayName ?? 'Usuario sin nombre'}', style: const TextStyle(color: Colors.green)),
              const SizedBox(height: 16),
              const Text('Configuración de Google Drive',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<drive.File>(
                      decoration: const InputDecoration(
                        labelText: 'Seleccionar Carpeta Existente',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: folders.any((f) => f.id == selectedFolder?.id)
                          ? folders.firstWhere((f) => f.id == selectedFolder?.id)
                          : null,
                      items: folders.map((drive.File folder) {
                        return DropdownMenuItem<drive.File>(
                          value: folder,
                          child: Text(folder.name ?? 'Unnamed Folder'),
                        );
                      }).toList(),
                      onChanged: (drive.File? newValue) {
                        if (newValue != null) {
                          onFolderSelected(newValue);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                      onPressed: onLoadFolders, child: const Text('Refrescar')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: selectedFolder?.id != null ? onLoadImages : null, 
                    child: const Text('Ver Imágenes')
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(child: Text('O Crear Carpeta Nueva:')),
                  ElevatedButton(
                    onPressed: () async {
                      if (newFolderNameController.text.isNotEmpty &&
                          driveService != null) {
                        final newFolder = await driveService!
                            .createFolder(newFolderNameController.text);
                        
                        if (!context.mounted) return;

                        if (newFolder != null) {
                          newFolderNameController.clear();
                          await onLoadFolders();
                          onFolderSelected(newFolder);
                        }
                      }
                    },
                    child: const Text('Crear y Usar'),
                  ),
                ],
              ),
              TextField(
                controller: newFolderNameController,
                decoration: const InputDecoration(
                  hintText: 'Ej: Newsletter_Imagenes_2024',
                ),
              ),
              const Divider(height: 32),
              const Text('Imágenes (subir a Google Drive)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                  'Selecciona todas las imágenes que quieras subir. Después, pulsa el botón de abajo para subirlas todas a la vez.'),
              const SizedBox(height: 16),
              _buildImageUploadRow('Logo (Cabecera)'),
              _buildImageUploadRow('Banner Principal'),
              _buildImageUploadRow('Miniatura Vídeo'),
              ...sections.asMap().entries.map((entry) {
                int idx = entry.key;
                return _buildImageUploadRow('Imagen (Sección ${idx + 1})');
              }),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    if (driveService == null || selectedFolder == null) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Por favor, selecciona una carpeta de destino en Google Drive.'),
                          ),
                        );
                      }
                      return;
                    }
                    
                    final filesToUpload = selectedFiles.entries
                        .where((entry) => entry.value != null)
                        .toList();
                        
                    if (filesToUpload.isEmpty) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No has seleccionado ningún archivo para subir.'),
                          ),
                        );
                      }
                      return;
                    }

                    final folderId = selectedFolder!.id;
                    if (folderId == null || folderId.isEmpty) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('La carpeta seleccionada no tiene un ID válido.'),
                          ),
                        );
                      }
                      return;
                    }

                    for (var entry in filesToUpload) {
                      final file = entry.value!;
                      if (file.bytes == null && file.path == null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('El archivo ${file.name} no tiene datos válidos.'),
                            ),
                          );
                        }
                        return;
                      }
                    }
                    
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return const Dialog(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(width: 20),
                                  Text("Subiendo archivos..."),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }

                    final Map<String, String> uploadedFileUrls = {};
                    for (var entry in filesToUpload) {
                      try {
                        final file = entry.value!;
                        final url = await driveService!
                            .uploadImageAndGetPublicUrl(file, folderId);
                        if (url != null) {
                          uploadedFileUrls[entry.key] = url;
                          onUrlReceived(entry.key, url);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al subir ${entry.key}: $e'), backgroundColor: Colors.red),
                          );
                        }
                        return;
                      }
                    }

                    if (context.mounted) {
                      Navigator.of(context).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Imágenes subidas y URLs actualizadas en los campos correspondientes.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                    
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Archivos Subidos'),
                            content: SizedBox(
                              width: double.maxFinite,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: uploadedFileUrls.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final label =
                                      uploadedFileUrls.keys.elementAt(index);
                                  final url =
                                      uploadedFileUrls.values.elementAt(index);
                                  return ListTile(
                                    title: Text(label),
                                    subtitle: Text(url,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.copy),
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: url));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'URL copiada al portapapeles')),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                            actions: [
                              TextButton(
                                child: const Text('Cerrar'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    }

                    onFilesUploaded();
                  },
                  child: const Text('Subir Todas las Imágenes Seleccionadas'),
                ),
              ),
              const Divider(height: 32),
              const Text('Vídeo (subir a YouTube)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildVideoUploadRow(context, 'Vídeo Principal'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadRow(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              selectedFiles[label]?.name ?? 'Ningún archivo seleccionado',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () async {
              final result =
                  await FilePicker.platform.pickFiles(type: FileType.image);
              if (result != null) {
                onFileSelected(label, result.files.first);
              }
            },
            child: const Text('Seleccionar'),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoUploadRow(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              selectedVideo?.name ?? 'Ningún vídeo seleccionado',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () async {
              final result =
                  await FilePicker.platform.pickFiles(type: FileType.video);
              if (result != null) {
                onVideoSelected(result.files.first);
              }
            },
            child: const Text('Seleccionar'),
          ),
          const SizedBox(width: 10),
          Builder(builder: (context) {
            return ElevatedButton(
              onPressed: (youTubeService == null || selectedVideo == null) ? null : () async {
                if (youTubeService == null || selectedVideo == null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Por favor, selecciona un vídeo para subir.')),
                    );
                  }
                  return;
                }

                if (context.mounted) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return const Dialog(
                        child: Padding(
                          padding: EdgeInsets.all(20.0), 
                          child: Row(
                                mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(width: 20),
                              Text("Subiendo vídeo..."),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }

                final uploadedVideo = await youTubeService!.uploadVideo(
                  selectedVideo!,
                  videoTitleController.text,
                  videoParagraphController.text,
                );

                if (context.mounted) {
                  Navigator.of(context).pop();

                  if (uploadedVideo != null) {
                    final videoUrl = 'https://www.youtube.com/watch?v=${uploadedVideo.id}';
                    videoLinkController.text = videoUrl;
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Vídeo Subido'),
                          content:
                              Text('El vídeo se ha subido con éxito.\n\nURL: $videoUrl'),
                          actions: [
                            TextButton(
                              child: const Text('Cerrar'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error al subir el vídeo.')),
                    );
                  }
                }
              },
              child: const Text('Subir Vídeo'),
            );
          }),
        ],
      ),
    );
  }
}

class _HeaderBannerCard extends StatelessWidget {
  final TextEditingController pageTitleController;
  final TextEditingController headerLinkController;
  final TextEditingController headerLogoUrlController;
  final TextEditingController bannerLinkController;
  final TextEditingController bannerImgUrlController;
  final TextEditingController bannerImgAltController;

  const _HeaderBannerCard({
    required this.pageTitleController,
    required this.headerLinkController,
    required this.headerLogoUrlController,
    required this.bannerLinkController,
    required this.bannerImgUrlController,
    required this.bannerImgAltController,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1. Cabecera y Banner',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildControllerTextField(
                controller: pageTitleController,
                labelText: 'Título de la Página (pestaña del navegador)'),
            _buildControllerTextField(
                controller: headerLinkController,
                labelText: 'Enlace del Logo (Cabecera)'),
            _buildControllerTextField(
                controller: headerLogoUrlController,
                labelText: 'URL de la Imagen del Logo (Cabecera)'),
            _buildControllerTextField(
                controller: bannerLinkController,
                labelText: 'Enlace del Banner Principal'),
            _buildControllerTextField(
                controller: bannerImgUrlController,
                labelText: 'URL de la Imagen del Banner Principal'),
            _buildControllerTextField(
                controller: bannerImgAltController,
                labelText: 'Texto Alternativo del Banner Principal'),
          ],
        ),
      ),
    );
  }

  Widget _buildControllerTextField({
    required TextEditingController controller,
    required String labelText,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _IntroContentCard extends StatelessWidget {
  final TextEditingController introTitleController;
  final HtmlEditorController introController1;
  final HtmlEditorController introController2;

  const _IntroContentCard({
    required this.introTitleController,
    required this.introController1,
    required this.introController2,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '2. Contenido Introductorio',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildControllerTextField(
              controller: introTitleController,
              labelText: 'Título Principal',
            ),
            const SizedBox(height: 16),
            const Text('Párrafo de Introducción 1'),
            HtmlEditor(
              controller: introController1,
              htmlEditorOptions: const HtmlEditorOptions(
                darkMode: false,
                initialText:
                    'El <strong>Centro de Innovación y Tecnología Educativa de Cantabria (CITED)</strong> es tu punto de referencia para la transformación digital en la educación.',
              ),
              htmlToolbarOptions: const HtmlToolbarOptions(
                toolbarPosition: ToolbarPosition.aboveEditor,
                defaultToolbarButtons: [
                  StyleButtons(),
                  FontSettingButtons(fontSize: false, fontName: false),
                  ColorButtons(),
                  ListButtons(listStyles: false),
                  ParagraphButtons(
                      textDirection: false,
                      lineHeight: false,
                      caseConverter: false),
                  InsertButtons(
                      video: false,
                      audio: false,
                      table: false,
                      hr: false,
                      otherFile: false),
                ],
              ),
              otherOptions: const OtherOptions(height: 200),
            ),
            const SizedBox(height: 16),
            const Text('Párrafo de Introducción 2'),
            HtmlEditor(
              controller: introController2,
              htmlEditorOptions: const HtmlEditorOptions(
                darkMode: false,
                initialText:
                    'Explora nuestras nuevas líneas de formación, programas, recursos y proyectos diseñados para <strong>docentes</strong> que buscan innovar en el aula.',
              ),
              htmlToolbarOptions: const HtmlToolbarOptions(
                defaultToolbarButtons: [
                  StyleButtons(),
                  FontSettingButtons(fontSize: false, fontName: false),
                  ColorButtons(),
                  ListButtons(listStyles: false),
                  ParagraphButtons(
                      textDirection: false,
                      lineHeight: false,
                      caseConverter: false),
                  InsertButtons(
                      video: false,
                      audio: false,
                      table: false,
                      hr: false,
                      otherFile: false),
                ],
              ),
              otherOptions: const OtherOptions(height: 200),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControllerTextField({
    required TextEditingController controller,
    required String labelText,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _DynamicSectionsManager extends StatelessWidget {
  final List<Section> sections;
  final VoidCallback onAddSection;
  final ValueChanged<int> onRemoveSection;
  final bool isDarkMode;
  final GoogleDriveService? driveService;
  final drive.File? selectedFolder;

  const _DynamicSectionsManager({
    required this.sections,
    required this.onAddSection,
    required this.onRemoveSection,
    required this.isDarkMode,
    required this.driveService,
    required this.selectedFolder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sections.length,
          itemBuilder: (context, index) {            
            return _buildSectionCard(context, index, isDarkMode);
          },
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton(
            onPressed: onAddSection,
            child: const Text('Añadir Sección'),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(BuildContext context, int index, bool isDarkMode) {
    final section = sections[index];

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sección ${index + 1}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (index > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => onRemoveSection(index),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildControllerTextField(
                controller: section.imgSrcController,
                labelText: 'URL de la Imagen'),
            const SizedBox(height: 8),
            _buildControllerTextField(
                controller: section.imgAltController,
                labelText: 'Texto Alternativo de la Imagen'),
            _buildControllerTextField(
                controller: section.titleController, labelText: 'Título'),
            const SizedBox(height: 16),
            const Text('Párrafo'),
            HtmlEditor(
              controller: section.paragraphController,
              htmlEditorOptions: HtmlEditorOptions(
                darkMode: isDarkMode,
                initialText: section.initialParagraph,
              ),
              htmlToolbarOptions: const HtmlToolbarOptions(
                toolbarPosition: ToolbarPosition.aboveEditor,
                defaultToolbarButtons: [
                  StyleButtons(),
                  FontSettingButtons(fontSize: false, fontName: false),
                  ColorButtons(),
                  ListButtons(listStyles: false),
                  ParagraphButtons(
                      textDirection: false,
                      lineHeight: false,
                      caseConverter: false),
                  InsertButtons(
                      video: false,
                      audio: false,
                      table: false,
                      hr: false,
                      otherFile: false),
                ],
              ),
              otherOptions: const OtherOptions(height: 200),
            ),
            const SizedBox(height: 16),
            _buildControllerTextField(
                controller: section.buttonTextController,
                labelText: 'Texto del Botón'),
            _buildControllerTextField(
                controller: section.buttonLinkController,
                labelText: 'Enlace del Botón (URL)'),
          ],
        ),
      ),
    );
  }

  Widget _buildControllerTextField({
    required TextEditingController controller,
    required String labelText,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _VideoSectionCard extends StatelessWidget {
  final YouTubeService? youTubeService;
  final PlatformFile? selectedVideo;
  final Function(PlatformFile) onVideoSelected;
  final TextEditingController videoTitleController;
  final TextEditingController videoParagraphController;
  final TextEditingController videoLinkController;
  final TextEditingController videoThumbnailUrlController;
  final TextEditingController videoThumbnailAltController;

  const _VideoSectionCard({
    required this.youTubeService,
    required this.selectedVideo,
    required this.onVideoSelected,
    required this.videoTitleController,
    required this.videoParagraphController,
    required this.videoLinkController,
    required this.videoThumbnailUrlController,
    required this.videoThumbnailAltController,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sección de Vídeo',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildControllerTextField(
                controller: videoTitleController, labelText: 'Título del Vídeo'),
            _buildControllerTextField(
                controller: videoParagraphController,
                labelText: 'Párrafo del Vídeo',
                maxLines: 3),
            _buildControllerTextField(
                controller: videoLinkController,
                labelText: 'Enlace al Archivo de Vídeo o Página'),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      selectedVideo?.name ?? 'Ningún vídeo seleccionado',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(type: FileType.video);
                      if (result != null) {
                        onVideoSelected(result.files.first);
                      }
                    },
                    child: const Text('Seleccionar'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: (youTubeService == null || selectedVideo == null) ? null : () async {
                      if (youTubeService == null || selectedVideo == null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Por favor, selecciona un vídeo para subir.')),
                          );
                        }
                        return;
                      }

                      if (context.mounted) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return const Dialog(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(width: 20),
                                    Text("Subiendo vídeo..."),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }

                      final uploadedVideo = await youTubeService!.uploadVideo(
                        selectedVideo!,
                        videoTitleController.text,
                        videoParagraphController.text,
                      );

                      if (context.mounted) {
                        Navigator.of(context).pop(); // Close loading dialog

                        if (uploadedVideo != null) {
                          final videoUrl = 'https://www.youtube.com/watch?v=${uploadedVideo.id}';
                          videoLinkController.text = videoUrl;
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Vídeo Subido'),
                                content: Text('El vídeo se ha subido con éxito.\n\nURL: $videoUrl'),
                                actions: [ TextButton( child: const Text('Cerrar'), onPressed: () => Navigator.of(context).pop(), ), ],
                              );
                            },
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Error al subir el vídeo.')), );
                        }
                      }
                    },
                    child: const Text('Subir Vídeo'),
                  ),
                ],
              ),
            ),
            _buildControllerTextField(
                controller: videoThumbnailUrlController,
                labelText: 'URL de la Imagen Miniatura del Vídeo'),
            _buildControllerTextField(
                controller: videoThumbnailAltController,
                labelText: 'Texto Alternativo de la Miniatura'),
          ],
        ),
      ),
    );
  }

  Widget _buildControllerTextField({
    required TextEditingController controller,
    required String labelText,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _StylesCard extends StatelessWidget {
  final Color backgroundColor;
  final Color titleColor;
  final Color paragraphColor;
  final Color buttonColor;
  final Color buttonTextColor;
  final ValueChanged<Color> onBackgroundColorChanged;
  final ValueChanged<Color> onTitleColorChanged;
  final ValueChanged<Color> onParagraphColorChanged;
  final ValueChanged<Color> onButtonColorChanged;
  final ValueChanged<Color> onButtonTextColorChanged;

  const _StylesCard({
    required this.backgroundColor,
    required this.titleColor,
    required this.paragraphColor,
    required this.buttonColor,
    required this.buttonTextColor,
    required this.onBackgroundColorChanged,
    required this.onTitleColorChanged,
    required this.onParagraphColorChanged,
    required this.onButtonColorChanged,
    required this.onButtonTextColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '7. Estilos de la Newsletter',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildColorField(
              labelText: 'Color de Fondo',
              color: backgroundColor,
              onColorChanged: onBackgroundColorChanged,
            ),
            _buildColorField(
              labelText: 'Color de los Títulos',
              color: titleColor,
              onColorChanged: onTitleColorChanged,
            ),
            _buildColorField(
              labelText: 'Color de los Párrafos',
              color: paragraphColor,
              onColorChanged: onParagraphColorChanged,
            ),
            _buildColorField(
              labelText: 'Color de Fondo de Botones',
              color: buttonColor,
              onColorChanged: onButtonColorChanged,
            ),
            _buildColorField(
              labelText: 'Color de Texto de Botones',
              color: buttonTextColor,
              onColorChanged: onButtonTextColorChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorField({
    required String labelText,
    required Color color,
    required Function(Color) onColorChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(child: Text(labelText)),
          const SizedBox(width: 16),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.grey),
              borderRadius: const BorderRadius.all(Radius.circular(4)),
            ),
          ),
          const SizedBox(width: 8),
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Selecciona un Color'),
                      content: SingleChildScrollView(
                        child: ColorPicker(
                          pickerColor: color,
                          onColorChanged: onColorChanged,
                          pickerAreaHeightPercent: 0.8,
                        ),
                      ),
                      actions: <Widget>[
                        ElevatedButton(
                          child: const Text('Hecho'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text('Seleccionar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterCard extends StatelessWidget {
  final TextEditingController footerLinkController;
  final TextEditingController footerLinkTextController;

  const _FooterCard({
    required this.footerLinkController,
    required this.footerLinkTextController,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '8. Pie de Página',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildControllerTextField(
                controller: footerLinkController,
                labelText: 'Enlace Web del Pie de Página'),
            _buildControllerTextField(
                controller: footerLinkTextController,
                labelText: 'Texto del Enlace Web del Pie de Página'),
          ],
        ),
      ),
    );
  }

  Widget _buildControllerTextField({
    required TextEditingController controller,
    required String labelText,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

// Clase Section
class Section {
  final TextEditingController imgSrcController;
  final TextEditingController imgAltController;
  final TextEditingController titleController;
  final HtmlEditorController paragraphController;
  final TextEditingController buttonLinkController;
  final TextEditingController buttonTextController;
  final String initialParagraph;

  Section({
    String imgSrc = '',
    String imgAlt = '',
    String title = '',
    String paragraph = '',
    String buttonLink = '',
    String buttonText = '',
  })  : imgSrcController = TextEditingController(text: imgSrc),
        imgAltController = TextEditingController(text: imgAlt),
        titleController = TextEditingController(text: title),
        paragraphController = HtmlEditorController(),
        buttonLinkController = TextEditingController(text: buttonLink),
        buttonTextController = TextEditingController(text: buttonText),
        initialParagraph = paragraph {
          if (paragraph.isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 100), () {
              paragraphController.setText(paragraph);
            });
          }
        }
}