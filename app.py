# -*- coding: utf-8 -*-
import os
import json
import io
import tempfile
from flask import Flask, render_template, request, session, redirect, url_for, jsonify
from pynliner import Pynliner
import google.oauth2.credentials
import google_auth_oauthlib.flow
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

app = Flask(__name__)
app.secret_key = os.urandom(24)

# Configuración de OAuth
CLIENT_SECRETS_FILE = "client_secret.json"
SCOPES = [
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/auth/youtube.upload',
    'https://www.googleapis.com/auth/drive.readonly' # Necesario para leer/descargar archivos
]
API_SERVICE_NAME = 'youtube'
API_VERSION = 'v3'

def get_drive_service():
    """
    Verifica las credenciales en la sesión y devuelve una instancia del servicio de Drive.
    Devuelve (None, error_response) si no está autenticado.
    """
    if 'credentials' not in session:
        return None, jsonify({'error': 'Not authenticated'}), 401
    
    try:
        credentials = google.oauth2.credentials.Credentials(**session['credentials'])
        drive_service = build('drive', 'v3', credentials=credentials)
        return drive_service, None, None
    except Exception as e:
        return None, jsonify({'error': 'Invalid credentials', 'details': str(e)}), 401

@app.route('/authorize')
def authorize():
    if os.path.exists(CLIENT_SECRETS_FILE):
        flow = google_auth_oauthlib.flow.Flow.from_client_secrets_file(
            CLIENT_SECRETS_FILE, scopes=SCOPES)
    else:
        client_config = {
            "web": {
                "client_id": os.environ.get("GOOGLE_CLIENT_ID"),
                "client_secret": os.environ.get("GOOGLE_CLIENT_SECRET"),
                "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                "token_uri": "https://oauth2.googleapis.com/token",
                "redirect_uris": [url_for('oauth2callback', _external=True)]
            }
        }
        flow = google_auth_oauthlib.flow.Flow.from_client_config(
            client_config, scopes=SCOPES)
    flow.redirect_uri = url_for('oauth2callback', _external=True)
    authorization_url, state = flow.authorization_url(
        access_type='offline',
        include_granted_scopes='true')
    session['state'] = state
    return redirect(authorization_url)

@app.route('/oauth2callback')
def oauth2callback():
    state = session['state']
    if os.path.exists(CLIENT_SECRETS_FILE):
        flow = google_auth_oauthlib.flow.Flow.from_client_secrets_file(
            CLIENT_SECRETS_FILE, scopes=SCOPES, state=state)
    else:
        client_config = {
            "web": {
                "client_id": os.environ.get("GOOGLE_CLIENT_ID"),
                "client_secret": os.environ.get("GOOGLE_CLIENT_SECRET"),
                "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                "token_uri": "https://oauth2.googleapis.com/token",
                "redirect_uris": [url_for('oauth2callback', _external=True)]
            }
        }
        flow = google_auth_oauthlib.flow.Flow.from_client_config(
            client_config, scopes=SCOPES, state=state)
    flow.redirect_uri = url_for('oauth2callback', _external=True)
    authorization_response = request.url
    flow.fetch_token(authorization_response=authorization_response)
    credentials = flow.credentials
    session['credentials'] = credentials_to_dict(credentials)
    return redirect(url_for('index'))

def credentials_to_dict(credentials):
    return {'token': credentials.token,
            'refresh_token': credentials.refresh_token,
            'token_uri': credentials.token_uri,
            'client_id': credentials.client_id,
            'client_secret': credentials.client_secret,
            'scopes': credentials.scopes}

@app.route('/get_or_create_folder', methods=['POST'])
def get_or_create_folder():
    drive_service, error_response, status_code = get_drive_service()
    if error_response:
        return error_response, status_code

    folder_name = request.form.get('folderName')
    if not folder_name:
        return jsonify({'error': 'No folder name provided'}), 400

    # Buscar si la carpeta ya existe
    query = "mimeType='application/vnd.google-apps.folder' and name='{}' and trashed=false".format(folder_name)
    response = drive_service.files().list(q=query, spaces='drive', fields='files(id, name)').execute()
    files = response.get('files', [])

    if files:
        # Carpeta encontrada
        folder_id = files[0].get('id')
        return jsonify({'folderId': folder_id})
    else:
        # Crear la carpeta
        file_metadata = {
            'name': folder_name,
            'mimeType': 'application/vnd.google-apps.folder'
        }
        folder = drive_service.files().create(body=file_metadata, fields='id').execute()
        return jsonify({'folderId': folder.get('id')})

@app.route('/upload_image', methods=['POST'])
def upload_image():
    drive_service, error_response, status_code = get_drive_service()
    if error_response:
        return error_response, status_code
    
    file = request.files['file']
    folder_id = request.form.get('folderId')

    if not file:
        return jsonify({'error': 'No file provided'}), 400
    
    # Create a temporary file and write the content to it
    with tempfile.NamedTemporaryFile(delete=False) as temp_file:
        file.stream.seek(0) # Ensure stream is at the beginning
        temp_file.write(file.stream.read())
        temp_file_path = temp_file.name

    response = None
    try:
        file_metadata = {
            'name': file.filename,
            'parents': [folder_id] if folder_id else []
        }

        media = MediaFileUpload(temp_file_path, mimetype=file.mimetype, resumable=True)
        
        request_drive = drive_service.files().create(media_body=media, body=file_metadata, fields='id, webViewLink, webContentLink')
        response = request_drive.execute()
    except Exception as e:
        print("Error uploading to Drive: {}".format(e))
    finally:
        # Clean up the temporary file
        os.remove(temp_file_path)

    if not response:
        return jsonify({'error': 'Failed to upload file to Google Drive'}), 500

    # Hacer el archivo público
    file_id = response.get('id')
    permission = {'type': 'anyone', 'role': 'reader'}
    drive_service.permissions().create(fileId=file_id, body=permission).execute()
    
    # Construir el enlace de descarga directa
    direct_link = "https://lh3.googleusercontent.com/d/{}".format(file_id)
    
    return jsonify({'url': direct_link})

@app.route('/upload_video', methods=['POST'])
def upload_video():
    if 'credentials' not in session:
        return jsonify({'error': 'Not authenticated'}), 401

    # Esta función necesita las credenciales, no el servicio de Drive
    credentials = google.oauth2.credentials.Credentials(**session['credentials'])
    youtube_service = build(API_SERVICE_NAME, API_VERSION, credentials=credentials)
    drive_service = build('drive', 'v3', credentials=credentials) # Necesario para obtener el enlace final

    file = request.files['file']
    if not file:
        return jsonify({'error': 'No file provided'}), 400
    
    # Create a temporary file and write the content to it
    with tempfile.NamedTemporaryFile(delete=False) as temp_file:
        file.stream.seek(0) # Ensure stream is at the beginning
        temp_file.write(file.stream.read())
        temp_file_path = temp_file.name

    response = None
    try:
        body = {
            'snippet': {
                'title': 'Video subido desde la App de Newsletter',
                'description': 'Este es un video subido a través de la aplicación de generación de newsletters.',
                'tags': ['newsletter', 'video'],
                'categoryId': '22' 
            },
            'status': {
                'privacyStatus': 'public' 
            }
        }

        media = MediaFileUpload(temp_file_path, chunksize=-1, resumable=True)
        
        request_youtube = youtube_service.videos().insert(
            part='snippet,status', # Corregido: 'part' debe ser una cadena explícita
            body=body,
            media_body=media
        )
        
        response = request_youtube.execute()
    except Exception as e:
        print("Error uploading to YouTube: {}".format(e))
    finally:
        # Clean up the temporary file
        os.remove(temp_file_path)
        
    if not response:
        return jsonify({'error': 'Failed to upload file to YouTube'}), 500

    video_id = response.get('id')
    video_url = "https://www.youtube.com/watch?v={}".format(video_id)
    
    return jsonify({'url': video_url})

@app.route('/delete_image/<image_id>', methods=['POST'])
def delete_image(image_id):
    drive_service, error_response, status_code = get_drive_service()
    if error_response:
        return error_response, status_code

    if not image_id:
        return jsonify({'error': 'Image ID is required'}), 400
    try:
        drive_service.files().delete(fileId=image_id).execute()
        return jsonify({'success': True, 'message': 'Imagen eliminada con éxito.'})
    except Exception as e:
        print("Error deleting image from Drive: {}".format(e))
        # Intenta dar un mensaje de error más específico si es posible
        error_message = str(e)
        if 'insufficient permissions' in error_message.lower():
            return jsonify({'error': 'Permisos insuficientes para eliminar el archivo.'}), 403
        if 'notFound' in error_message:
            return jsonify({'error': 'El archivo no fue encontrado. Puede que ya haya sido eliminado.'}), 404
        
        return jsonify({'error': 'No se pudo eliminar la imagen de Google Drive.'}), 500


@app.route('/list_drive_folders', methods=['GET'])
def list_drive_folders():
    drive_service, error_response, status_code = get_drive_service()
    if error_response:
        return error_response, status_code

    folders = []
    page_token = None
    try:
        while True:
            response = drive_service.files().list(
                q="mimeType='application/vnd.google-apps.folder' and trashed=false",
                spaces='drive',
                fields='nextPageToken, files(id, name)',
                pageToken=page_token
            ).execute()
            
            for file in response.get('files', []):
                folders.append({'id': file.get('id'), 'name': file.get('name')})
            
            page_token = response.get('nextPageToken', None);
            if page_token is None:
                break
        
        # Ordenar las carpetas alfabéticamente por nombre
        folders.sort(key=lambda x: x['name'].lower())
        
        return jsonify(folders)

    except Exception as e:
        print("Error listing Drive folders: {}".format(e))
        return jsonify({'error': 'Failed to list folders from Google Drive'}), 500

@app.route('/', methods=['GET', 'POST'])
def index():
    if request.method == 'POST':
        # Recoger datos del formulario
        context = {
            'title': request.form.get('title'),
            'header_logo_link': request.form.get('header_logo_link'),
            'header_logo_src': request.form.get('header_logo_src'),
            'hero_link': request.form.get('hero_link'),
            'hero_src': request.form.get('hero_src'),
            'hero_alt': request.form.get('hero_alt'),
            'intro_title': request.form.get('intro_title'),
            'intro_p1': request.form.get('intro_p1'),
            'intro_p2': request.form.get('intro_p2'),
            'video_title': request.form.get('video_title'),
            'video_p': request.form.get('video_p'),
            'video_link': request.form.get('video_link'),
            'video_thumbnail_src': request.form.get('video_thumbnail_src'),
            'video_thumbnail_alt': request.form.get('video_thumbnail_alt'),
            'footer_web_link': request.form.get('footer_web_link'),
            'footer_text_main': request.form.get('footer_text_main'),
            'footer_web_text': request.form.get('footer_web_text'),
            'footer_legal_text': request.form.get('footer_legal_text'),
            'bg_type': request.form.get('bg_type'),
            'bg_color': request.form.get('bg_color'),
            'bg_color_1': request.form.get('bg_color_1'),
            'bg_color_2': request.form.get('bg_color_2'),
            'title_color': request.form.get('title_color'),
            'text_color': request.form.get('text_color'),
            'button_color': request.form.get('button_color'),
            'font_family': request.form.get('font_family'),
            'title_font_size': request.form.get('title_font_size'),
            'sections': []
        }

        # Recoger secciones dinámicamente
        sections_data = {}
        for key, value in request.form.items():
            if key.startswith('section'):
                parts = key.split('_')
                section_num = parts[0].replace('section', '')
                field_name = '_'.join(parts[1:])
                
                if section_num not in sections_data:
                    sections_data[section_num] = {'id': section_num}
                sections_data[section_num][field_name] = value
        
        # Convertir el diccionario de secciones a una lista ordenada
        sorted_section_nums = sorted(sections_data.keys(), key=int)
        context['sections'] = [sections_data[num] for num in sorted_section_nums]

        # Guardar todo el contexto en la sesión para repoblar el formulario
        session['form_data'] = context

        # Renderizar la plantilla de la newsletter a una variable
        newsletter_html = render_template('template.html', **context)
        
        # Inliner los estilos CSS
        p = Pynliner()
        newsletter_html = p.from_string(newsletter_html).run()
        session['form_data'] = context # Guardar datos antes de mostrar el resultado

        # Devolver la página de resultados con el código de la newsletter
        return render_template('result.html', newsletter_html=newsletter_html)
    
    # Si es GET, mostrar el formulario con los datos de la sesión si existen
    form_data = session.get('form_data', {})
    credentials_exist = 'credentials' in session
    return render_template('index.html', credentials_exist=credentials_exist, form_data=form_data)


@app.route('/list_images_in_folder/<folder_id>', methods=['GET'])
def list_images_in_folder(folder_id):
    drive_service, error_response, status_code = get_drive_service()
    if error_response:
        return error_response, status_code

    images = []
    page_token = None
    try:
        while True:
            response = drive_service.files().list(
                q="'{}' in parents and mimeType contains 'image/' and trashed=false".format(folder_id),
                spaces='drive',
                fields='nextPageToken, files(id, name)',
                pageToken=page_token
            ).execute()
            
            for file in response.get('files', []):
                file_id = file.get('id')
                direct_link = "https://lh3.googleusercontent.com/d/{}".format(file_id)
                images.append({
                    'id': file_id, 
                    'name': file.get('name'), 
                    'url': direct_link
                })
            
            page_token = response.get('nextPageToken', None)
            if page_token is None:
                break
        
        images.sort(key=lambda x: x['name'].lower())
        return jsonify(images)

    except Exception as e:
        print("Error listing images in folder: {}".format(e))
        return jsonify({'error': 'Failed to list images from Google Drive folder'}), 500

@app.route('/manage_images/<folder_id>', methods=['GET'])
def manage_images_page(folder_id):
    if 'credentials' not in session:
        return redirect(url_for('authorize'))

    drive_service, error_response, status_code = get_drive_service()
    if error_response: # Si las credenciales son inválidas, redirige
        return redirect(url_for('authorize'))
    images = []
    try:
        response = drive_service.files().list(
            q="'{}' in parents and mimeType contains 'image/' and trashed=false".format(folder_id),
            spaces='drive',
            fields='files(id, name)'
        ).execute()
        
        for file in response.get('files', []):
            file_id = file.get('id')
            direct_link = "https://lh3.googleusercontent.com/d/{}".format(file_id)
            images.append({'id': file_id, 'name': file.get('name'), 'url': direct_link})
        
        images.sort(key=lambda x: x['name'].lower())
    except Exception as e:
        print("Error en manage_images_page: {}".format(e))
        # Podrías redirigir a una página de error o de vuelta al formulario con un mensaje.

    form_data = session.get('form_data', {})
    return render_template('manage_images.html', images=images, form_data=form_data)

@app.route('/save_template', methods=['POST'])
def save_template():
    drive_service, error_response, status_code = get_drive_service()
    if error_response or 'form_data' not in session:
        return jsonify({'error': 'No form data to save'}), 400

    data = request.get_json()
    filename = data.get('filename')
    if not filename:
        return jsonify({'error': 'Filename is required'}), 400

    # Asegurarse de que el nombre del archivo termine en .json
    if not filename.endswith('.json'):
        filename += '.json'

    # 1. Buscar o crear la carpeta "Newsletter_Templates"
    folder_name = "Newsletter_Templates"
    query = "mimeType='application/vnd.google-apps.folder' and name='{}' and trashed=false".format(folder_name)
    response = drive_service.files().list(q=query, spaces='drive', fields='files(id)').execute()
    files = response.get('files', [])

    if files:
        folder_id = files[0].get('id')
    else:
        file_metadata = {'name': folder_name, 'mimeType': 'application/vnd.google-apps.folder'}
        folder = drive_service.files().create(body=file_metadata, fields='id').execute()
        folder_id = folder.get('id')

    # 2. Guardar los datos del formulario como un archivo JSON en esa carpeta
    template_data = json.dumps(session['form_data'], indent=4)
    
    try:
        # Usar un archivo temporal para la subida
        with tempfile.NamedTemporaryFile(mode='w+', delete=False, suffix='.json', encoding='utf-8') as temp_file:
            temp_file.write(template_data)
            temp_file_path = temp_file.name

        media = MediaFileUpload(temp_file_path, mimetype='application/json', resumable=True)
        file_metadata = {'name': filename, 'parents': [folder_id]}
        drive_service.files().create(body=file_metadata, media_body=media, fields='id').execute()
        os.remove(temp_file_path) # Limpiar el archivo temporal
        return jsonify({'success': True, 'message': 'Plantilla "{}" guardada en Google Drive.'.format(filename)})
    except Exception as e:
        print("Error saving template to Drive: {}".format(e))
        return jsonify({'error': 'Failed to save template to Google Drive'}), 500

@app.route('/list_templates', methods=['GET'])
def list_templates():
    drive_service, error_response, status_code = get_drive_service()
    if error_response:
        return error_response, status_code

    # Buscar la carpeta "Newsletter_Templates"
    folder_name = "Newsletter_Templates"
    query = "mimeType='application/vnd.google-apps.folder' and name='{}' and trashed=false".format(folder_name)
    response = drive_service.files().list(q=query, spaces='drive', fields='files(id)').execute()
    if not response.get('files', []):
        return jsonify([]) # No hay carpeta, por lo tanto no hay plantillas

    folder_id = response.get('files')[0].get('id')

    # Listar archivos .json en la carpeta
    query = "'{}' in parents and mimeType='application/json' and trashed=false".format(folder_id)
    response = drive_service.files().list(q=query, spaces='drive', fields='files(id, name)').execute()
    templates = response.get('files', [])
    
    return jsonify(sorted(templates, key=lambda x: x['name'].lower()))

@app.route('/load_template/<template_id>', methods=['GET'])
def load_template(template_id):
    if 'credentials' not in session:
        return redirect(url_for('authorize')) # Redirige a login si no hay sesión
    drive_service, error_response, status_code = get_drive_service()
    if error_response: # Redirige a login si las credenciales son inválidas
        return redirect(url_for('authorize'))
    try:
        # Forma actualizada y más simple de descargar el contenido del archivo
        file_content = drive_service.files().get_media(fileId=template_id).execute()
        
        # Decodificar el contenido y cargarlo como JSON
        template_data = json.loads(file_content.decode('utf-8'))
        session['form_data'] = template_data
        return redirect(url_for('index'))
    except Exception as e:
        print("Error loading template from Drive: {}".format(e))
        # Aquí podrías redirigir a una página de error o mostrar un flash message
        return "Error al cargar la plantilla desde Google Drive: {}".format(e), 500

@app.route('/delete_template/<template_id>', methods=['DELETE'])
def delete_template(template_id):
    drive_service, error_response, status_code = get_drive_service()
    if error_response:
        return error_response, status_code
    try:
        drive_service.files().delete(fileId=template_id).execute()
        return jsonify({'success': True, 'message': 'Plantilla eliminada con éxito.'})
    except Exception as e:
        print("Error deleting template from Drive: {}".format(e))
        error_message = str(e)
        if 'insufficient permissions' in error_message.lower():
            return jsonify({'error': 'Permisos insuficientes para eliminar la plantilla.'}), 403
        if 'notFound' in error_message:
            return jsonify({'error': 'La plantilla no fue encontrada. Puede que ya haya sido eliminada.'}), 404
        
        return jsonify({'error': 'No se pudo eliminar la plantilla de Google Drive.'}), 500

@app.route('/manage_images', methods=['POST'])
def manage_images_view():
    # Guardamos los datos del formulario que vienen del POST en la sesión
    session['form_data'] = request.form.to_dict(flat=True)
    folder_id = request.form.get('drive_folder_id')
    if not folder_id:
        # Si no hay folder_id, no podemos continuar. Volvemos al formulario.
        return redirect(url_for('index'))
    return redirect(url_for('manage_images_page', folder_id=folder_id))

if __name__ == '__main__':
    os.environ['OAUTHLIB_INSECURE_TRANSPORT'] = '1'
    os.environ['OAUTHLIB_RELAX_TOKEN_SCOPE'] = '1'
    app.run(debug=True)