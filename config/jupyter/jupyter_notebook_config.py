import json
import os
import sys

home = os.environ['HOME']
jupyterPrefs_dir = '{0}/.jupyter/'.format(home)
jP_static = jupyterPrefs_dir + 'static'
jP_extensions = jupyterPrefs_dir + 'extensions/'
jP_nbconfig_json = jupyterPrefs_dir + 'nbconfig/common.json'

sys.path.append(jupyterPrefs_dir)

c.JupyterApp.ip = '*'
c.JupyterApp.port = 80
c.JupyterApp.open_browser = False
c.JupyterApp.allow_credentials = True
c.JupyterApp.nbserver_extensions = ['jupyter_nbgallery.status', 'jupyter_nbgallery.post']
c.JupyterApp.reraise_server_extension_failures = True
c.JupyterApp.extra_static_paths = [jP_static]
c.JupyterApp.extra_nbextensions_path = [jP_extensions]
c.JupyterApp.tornado_settings = {'static_url_prefix': '/Jupyter/static/'}
c.JupyterApp.allow_origin = 'https://localhost:3000'

# needed to receive notebooks from the gallery
c.JupyterApp.disable_check_xsrf = True

# Update config from environment
config_prefix = 'NBGALLERY_CONFIG_'
for var in [x for x in os.environ if x.startswith(config_prefix)]:
  c.JupyterApp[var[len(config_prefix):].lower()] = os.environ[var]

def load_config():
  return json.loads(open(jP_nbconfig_json).read())

def save_config(config):
  with open(jP_nbconfig_json) as output:
    output.write(json.dumps(config, indent=2))

# Override gallery location
nbgallery_url = os.getenv('NBGALLERY_URL')
if nbgallery_url:
  print('Setting nbgallery url to %s' % nbgallery_url)
  c.JupyterApp.allow_origin = nbgallery_url
  config = load_config()
  config['nbgallery']['url'] = nbgallery_url
  save_config(config)

# Override client name
client_name = os.getenv('NBGALLERY_CLIENT_NAME')
if client_name:
  config = load_config()
  config['nbgallery']['client']['name'] = client_name
  save_config(config)

# Enable optional nbgallery extensions
if os.getenv('NBGALLERY_ENABLE_INSTRUMENTATION'):
  config = load_config()
  config['nbgallery']['extra_integration']['notebook'].append('gallery-instrumentation.js')
  save_config(config)
if os.getenv('NBGALLERY_ENABLE_AUTODOWNLOAD'):
  config = load_config()
  config['nbgallery']['extra_integration']['tree'].append('gallery-autodownload.js')
  save_config(config)
