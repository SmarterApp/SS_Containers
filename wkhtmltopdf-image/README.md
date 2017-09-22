# smarterbalanced/wkhtmltopdf-image

This docker image provides a service wrapper around the open-source HTML to PDF conversion tool [wkhtmltopdf](https://wkhtmltopdf.org/)
and is designed to be used as a service for generating PDF files from HTML sources.

This image is based on [openlabs/docker-wkhtmltopdf-aas](https://github.com/openlabs/docker-wkhtmltopdf-aas)
and is extended to support data streaming to avoid temporary file-system storage.

## License

Copyright (c) 2014, Openlabs Technologies & Consulting (P) Limited
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of the {organization} nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

## Clone
To clone the repository enter the following git command:
```bash
git clone https://github.com/SmarterApp/SS_Containers.git
```

## Build
To build the docker image, move to the project root directory and run the below maven command:
```bash
mvn package docker:build
```
Alternatively, for local development, the docker image can be built directly with Docker by running the following commands:
```bash
docker image build src/main/docker
```

## Run
To start the docker image as a local service run the following command:
```bash
docker run -d -p 300:80 smarterbalanced/wkhtmltopdf-image:latest
```
This forwards ```localhost:300``` to the docker container port ```80```.

Port ```300``` was arbitrarily selected for this example and can be set to any port that is not in use.

Port ```80``` however, is the port smarterbalanced/wkhtmltopdf-image exposes its interface on.

## Test
### HTML to PDF
The below command sends a base 64 encoded sample HTML page with ```<body>Sample PDF</body>``` to the service.
```bash
curl -X POST -d '{"contents": "PCFET0NUWVBFIGh0bWw+DQo8aHRtbD4NCjxoZWFkPg0KPHRpdGxlPlNhbXBsZSBQREY8L3RpdGxlPg0KPC9oZWFkPg0KPGJvZHk+U2FtcGxlIFBERg0KPC9ib2R5Pg0KPC9odG1sPg=="}' -H 'Content-Type: application/json' http://localhost:8080 -o sample.pdf
```
The service then responds with a PDF containing the text "Sample PDF" which is saved to your current directory as ```sample.pdf```.
### Health
To check that the service is running and healthy you can run:
```bash
curl -v http://localhost:300/health 2>&1 | grep '< HTTP'
```
This should print the response:
```bash
< HTTP/1.1 200 OK
```

## API

### HTML to PDF
**Endpoint:** ```/```

**Method:** ```POST```

**Headers:**
* **Required:**

  ```Content-Type: application/json```

**Data Params:** 
* **Required:**

  ```"contents": [string]``` Base 64 encoded HTML string

* **Optional:**

  ```"options": [object]``` Map of wkhtmltopf options to arguments. This map accepts all options defined in [wkhtmltopdf documentation](https://wkhtmltopdf.org/usage/wkhtmltopdf.txt) but only in verbose form. (e.g. ```"dpi": 300``` will be accepted but ```"d": 300``` will not). Also options without arguments should be passed with a blank string or they will be ignored. (e.g. Pass ```"grayscale": ""``` instead of ```"grayscale": null```)
  
* **Example:**
  
  Below is an example of setting the ```--page-size``` option which accepts one argument and the ```--grayscale``` option which accepts no arguments.
  ```javascript
  {
      "contents": "<base_64_encoded_html_string>",
      "options": {
          "page-size": "Letter",
          "grayscale": ""
      }
  }
  ```
### Health
**Endpoint:** ```/health```

**Method:** ```GET```

**Response:**  
* **Success:** ```200 OK```