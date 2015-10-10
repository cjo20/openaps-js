#!/bin/bash

# Author: Ben West @bewest
# Maintainer: Chris Oattes @cjo20

# Written for decocare v0.0.17. Will need updating the the decocare json format changes.
HISTORY=${1-glucosehistory.json}
OUTPUT=${2-/dev/fd/1}
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

