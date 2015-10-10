#!/bin/bash

# Author: Ben West, Maintainer: Scott Leibrand

# Written for decocare v0.0.17. Will need updating the the decocare json format changes.
HISTORY=${1-treatmenthistory.json}
OUTPUT=${2-treatmenthistory.ns.json}
#TZ=${3-$(date +%z)}

cat $HISTORY | \
  json -C "this._type == 'Bolus' || this._type == 'BolusWizard'" | \
  json -E "this.created_at = this.timestamp + '$(date +%z)'" | \
  json -E "this._type == 'Bolus' ? this.eventType = 'Bolus' : this.eventType = 'carbs'" | \
  json -E "if(this._type == 'Bolus') { this.insulin = this.amount; }" | \
  json -E "if (this._type == 'BolusWizard') { this.carbs = this.carb_input; }" | \
  json -E "this.device = 'openaps://medtronic/pump/cgm'" | \
  json -E "delete this.programmed" | \
  json -E "delete this._date" | \
  json -E "delete this._head" | \
  json -E "delete this._body" | \
  json -E "delete this._description" | \
  json -E "delete this.bg" |\
  json -E "delete this.type" |\
  json -E "this.enteredBy = 'openaps'" | \
  json -E "delete this._tell" \
  > $OUTPUT

# requires API_SECRET and NIGHTSCOUT_HOST to be set in calling environment (i.e. in crontab)
curl -s -X POST --data-binary @$OUTPUT -H "API-SECRET: $API_SECRET" -H "content-type: application/json" $NIGHTSCOUT_HOST/api/v1/treatments.json >/dev/null && ( touch /tmp/openaps.online && echo "Uploaded $OUTPUT to $NIGHTSCOUT_HOST" ) || echo "Unable to upload to $NIGHTSCOUT_HOST"
