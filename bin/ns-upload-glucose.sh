#!/bin/bash

# Author: Ben West, Maintainer: Scott Leibrand

# Written for decocare v0.0.17. Will need updating the the decocare json format changes.
HISTORY=${1-glucosehistory.json}
OUTPUT=${2-glucosehistory.ns.json}
#TZ=${3-$(date +%z)}

cat $HISTORY | \
  json -E "this.medtronic = this._type;" | \
  json -E "this.dateString = this.date + '$(date +%z)'" | \
  json -E "this.date = new Date(this.dateString).getTime();" | \
  json -E "this.type = (this.name == 'GlucoseSensorData') ? 'sgv' : 'pumpdata'" | \
  json -C "this.type == 'sgv'" | \
  json -E "this.device = 'openaps://medtronic/pump/cgm'" | \
  json -E "delete this._tell" \
  > $OUTPUT

# requires API_SECRET and NIGHTSCOUT_HOST to be set in calling environment (i.e. in crontab)
curl -s -X POST --data-binary @$OUTPUT -H "API-SECRET: $API_SECRET" -H "content-type: application/json" $NIGHTSCOUT_HOST/api/v1/entries.json >/dev/null && ( touch /tmp/openaps.online && echo "Uploaded $OUTPUT to $NIGHTSCOUT_HOST" ) || echo "Unable to upload to $NIGHTSCOUT_HOST"
