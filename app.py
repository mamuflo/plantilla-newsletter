# -*- coding: utf-8 -*-
from flask import Flask, render_template, request, session
from pynliner import Pynliner
import os

app = Flask(__name__)
app.secret_key = os.urandom(24)

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
    return render_template('index.html', **styles)

if __name__ == '__main__':
    app.run(debug=True)