'use strict';

exports.handler = (event, context, callback) => {
  // passed in from terraform template vars
  //
  let primary_alias = '${primary_alias}';
  let default_root_object = '${default_root_object}';
  let enable_deep_default_objects = ${enable_deep_default_objects};
  let enable_redirects = ${enable_redirects};

  const request = event.Records[0].cf.request;
  const headers = request.headers;

  // console.log(`Started request: $${JSON.stringify(request)}`);

  // for host or scheme mismatch, do redirect
  //
  if (enable_redirects && headers.host[0].value !== primary_alias) {

    const redirect_url = `https://$${primary_alias}$${request.uri}`;
    if (request.querystring != "") {
      redirect_url += `?$${request.querystring}`
    }

    const response = {
      status: '301',
      headers: {
        location: [{
          key: 'Location',
          value: redirect_url,
        }],
      },
    };

    console.log(`Redirecting request to $${headers.host[0].value} => $${redirect_url}`);

    return callback(null, response);
  }

  // for non-files, rewrite the origin request to handle deep default objects
  //
  if (enable_deep_default_objects && request.uri !== "/") {
    let segments = request.uri.split('/');
    let last_segment = segments[segments.length - 1];
    let is_file = last_segment.split('.').length > 1;
    let rewritten_url = request.uri;

    if (!is_file) {
      if (last_segment != "") {
        rewritten_url += "/";
      }

      rewritten_url += default_root_object;
      console.log(`Rewriting origin uri: $${request.uri} => $${rewritten_url}`);
      request.uri = rewritten_url;
    }

  }

  callback(null, request);
}
