# -*- coding: utf-8 -*-
import os
import json
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
    'https://www.googleapis.com/auth/youtube.upload'
]
API_SERVICE_NAME = 'youtube'
API_VERSION = 'v3'

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
    if 'credentials' not in session:
        return jsonify({'error': 'Not authenticated'}), 401

    credentials = google.oauth2.credentials.Credentials(**session['credentials'])
    drive_service = build('drive', 'v3', credentials=credentials)

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
    if 'credentials' not in session:
        return jsonify({'error': 'Not authenticated'}), 401
    
    credentials = google.oauth2.credentials.Credentials(**session['credentials'])
    drive_service = build('drive', 'v3', credentials=credentials)
    
    file = request.files['file']
    folder_id = request.form.get('folderId')

    if not file:
        return jsonify({'error': 'No file provided'}), 400

    file_metadata = {
        'name': file.filename,
        'parents': [folder_id] if folder_id else []
    }

    media = MediaFileUpload(file, mimetype=file.mimetype, resumable=True)
    
    request_drive = drive_service.files().create(media_body=media, body=file_metadata, fields='id, webViewLink')
    response = request_drive.execute()
    
    # Hacer el archivo público
    file_id = response.get('id')
    permission = {'type': 'anyone', 'role': 'reader'}
    drive_service.permissions().create(fileId=file_id, body=permission).execute()
    
    # Obtener el enlace público
    file_data = drive_service.files().get(fileId=file_id, fields='webViewLink').execute()
    
    return jsonify({'url': file_data['webViewLink']})

@app.route('/upload_video', methods=['POST'])
def upload_video():
    if 'credentials' not in session:
        return jsonify({'error': 'Not authenticated'}), 401

    credentials = google.oauth2.credentials.Credentials(**session['credentials'])
    youtube_service = build(API_SERVICE_NAME, API_VERSION, credentials=credentials)

    file = request.files['file']
    if not file:
        return jsonify({'error': 'No file provided'}), 400

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

    media = MediaFileUpload(file, chunksize=-1, resumable=True)
    
    request_youtube = youtube_service.videos().insert(
        part=','.join(body.keys()),
        body=body,
        media_body=media
    )
    
    response = request_youtube.execute()
    # Obtener el ID del video de la respuesta de YouTube
    video_id = response.get('id')
    video_url = "https://www.youtube.com/watch?v={}".format(video_id)

    return jsonify({'url': video_url})


@app.route('/')
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
            'section1_img_src': request.form.get('section1_img_src'),
            'section1_img_alt': request.form.get('section1_img_alt'),
            'section1_title': request.form.get('section1_title'),
            'section1_p': request.form.get('section1_p'),
            'section1_button_link': request.form.get('section1_button_link'),
            'section1_button_text': request.form.get('section1_button_text'),
            'section2_img_src': request.form.get('section2_img_src'),
            'section2_img_alt': request.form.get('section2_img_alt'),
            'section2_title': request.form.get('section2_title'),
            'section2_p': request.form.get('section2_p'),
            'section2_button_link': request.form.get('section2_button_link'),
            'section2_button_text': request.form.get('section2_button_text'),
            'video_title': request.form.get('video_title'),
            'video_p': request.form.get('video_p'),
            'video_link': request.form.get('video_link'),
            'video_thumbnail_src': request.form.get('video_thumbnail_src'),
            'video_thumbnail_alt': request.form.get('video_thumbnail_alt'),
            'footer_web_link': request.form.get('footer_web_link'),
            'footer_web_text': request.form.get('footer_web_text'),
            'bg_type': request.form.get('bg_type'),
            'bg_color': request.form.get('bg_color'),
            'bg_color_1': request.form.get('bg_color_1'),
            'bg_color_2': request.form.get('bg_color_2'),
            'title_color': request.form.get('title_color'),
            'text_color': request.form.get('text_color'),
            'font_family': request.form.get('font_family'),
            'title_font_size': request.form.get('title_font_size'),
        }

        # Guardar estilos en la sesión
        session['styles'] = {
            'bg_type': context['bg_type'],
            'bg_color': context['bg_color'],
            'bg_color_1': context['bg_color_1'],
            'bg_color_2': context['bg_color_2'],
            'title_color': context['title_color'],
            'text_color': context['text_color'],
            'font_family': context['font_family'],
            'title_font_size': context['title_font_size'],
        }

        # Renderizar la plantilla de la newsletter a una variable
        newsletter_html = render_template('template.html', **context)
        
        # Inliner los estilos CSS
        p = Pynliner()
        newsletter_html = p.from_string(newsletter_html).run()

        # Devolver la página de resultados con el código de la newsletter
        return render_template('result.html', newsletter_html=newsletter_html)
    
    # Si es GET, mostrar el formulario con los estilos de la sesión si existen
    styles = session.get('styles', {})
    credentials_exist = 'credentials' in session
    return render_template('index.html', credentials_exist=credentials_exist, **styles)

if __name__ == '__main__':
    os.environ['OAUTHLIB_INSECURE_TRANSPORT'] = '1'
    app.run(debug=True)