#! /usr/bin/env python
import StringIO
import json
from subprocess import Popen, PIPE

from werkzeug.exceptions import HTTPException, NotFound
from werkzeug.routing import Map, Rule
from werkzeug.wrappers import Request, Response

"""
This python server is responsible for generating PDFs from HTML
using an underlying wkhtmltopdf command-line tool.

To use this application, the user must send a POST request with
base64 or form encoded encoded HTML content and the wkhtmltopdf Options in
request data, with keys 'contents' and 'options'.
The application will return a response with the PDF file.
"""
class WkHtmlToPdfServer():
    def __init__(self):
        self.url_map = Map([
            Rule('/', endpoint='generate_pdf'),
            Rule('/health', endpoint='health_check')
        ])

    """
    Generate a PDF from submitted HTML.
    """
    def on_generate_pdf(self, request):
        if request.method != 'POST':
            return

        request_is_json = request.content_type.endswith('json')
        sourceStream = None
        options = None

        if request_is_json:
            # If a JSON payload is there, all data is in the payload
            payload = json.loads(request.get_data(parse_form_data=True, cache=False))
            sourceStream = StringIO.StringIO(payload['contents'].decode('base64'))
            options = payload.get('options', {})
        elif request.files:
            # First check if any files were uploaded
            sourceStream = request.files['file'].stream
            # Load any options that may have been provided in options
            options = json.loads(request.form.get('options', '{}'))

        # Evaluate argument to run with subprocess
        args = [u'wkhtmltopdf']

        # Add Global Options
        if options:
            for option, value in options.items():
                args.append("--%s" % option)
                if value:
                    args.append('%s' % value)

        #Pipe source and output to/from STDIN/STDOUT
        args.append(u'-')
        args.append(u'-')

        cliProc = Popen(args, stdin=PIPE, stdout=PIPE)
        try:
            for block in iter(lambda: sourceStream.read(8096), ""):
                cliProc.stdin.write(block)
            sourceStream.close()
            cliProc.stdin.close()
        except:
            cliProc.kill()

        return Response(
            cliProc.stdout,
            mimetype='application/pdf',
        )

    """
    Respond to a health check request with a 200 Healthy status.
    """
    def on_health_check(self, request):
        return Response(status=200)

    """
    Respond with 404 for unknown requests.
    """
    @staticmethod
    def error_404():
        return Response(status=404)

    """
    Dispatch a request to the associated handler.
    """
    def dispatch_request(self, request):
        adapter = self.url_map.bind_to_environ(request.environ)
        try:
            endpoint, values = adapter.match()
            return getattr(self, 'on_' + endpoint)(request, **values)
        except NotFound:
            return self.error_404()
        except HTTPException, e:
            return e

    """
    Initialize the Request object, then dispatch the request.
    """
    def wsgi_app(self, environ, start_response):
        request = Request(environ)
        response = self.dispatch_request(request)
        return response(environ, start_response)

    """
    When called, handle the request.
    """
    def __call__(self, environ, start_response):
        return self.wsgi_app(environ, start_response)

if __name__ == '__main__':
    from werkzeug.serving import run_simple
    run_simple('127.0.0.1', 5000, WkHtmlToPdfServer(), use_debugger=True, use_reloader=True)