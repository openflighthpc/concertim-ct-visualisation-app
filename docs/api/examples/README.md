# Example scripts for using the rack and device API

These example scripts demonstrate usage of the rack and device API.  Example
scripts for the metric API can be found at
https://github.com/alces-flight/concertim-metric-reporting-daemon/tree/main/docs/examples.

For the best experience you will want to ensure that you are viewing the
example scripts for the same release as the Concertim instance.

## Authentication and selecting the Concertim instance

The example scripts are created to make it easy to specify which Concertim
instance to communicate with.  This is done via setting the `CONCERTIM_HOST`
environment variable.  If this is not set it will default to
`command.concertim.alces-flight.com`.

It is currently left as an exercise for the API user to either ensure that that
the name `command.concertim.alces-flight.com` resolves to the correct IP
address or alternatively to specify `CONCERTIM_HOST`.

To use the API an authentication token needs to be obtained.  The example below
does so using a Concertim instance available at `10.151.15.150`.  The snippet
is intended to be ran from within the rack and device API example script
directory.

```
export CONCERTIM_HOST=10.151.15.150
export AUTH_TOKEN=$(LOGIN=admin PASSWORD=admin ./get-auth-token.sh)
```

With `AUTH_TOKEN` and `CONCERTIM_HOST` both exported the other API example
scripts can be used.

## Rack and device API usage

### Cloud environment config

Get the configured cloud environment config.  If the configuration has not yet
been created a 404 response is returned.

```
./show-cloud-env-config.sh
```

### Users

List all users.  Returns a list of all users that the current user is permitted
to view.  For admin users this is all users, for non-admin users this is their
own user.

```
./list-users.sh
```

Get details of current user.  Provides details of the current user.

```
./current-user.sh
```

Update cloud user ID, project ID or billing acct ID for a given user.  Setting
`CLOUD_USER_ID`, `PROJECT_ID` or `BILLING_ACCT_ID` to `""` will unset the value
for the user.

```
./update-user.sh <USER_ID> <CLOUD_USER_ID> <PROJECT_ID> <BILLING_ACCT_ID>
```

Update cost for the current billing period, the billing period start date and the billing period end date for a given user.
Billing period start and end should be date strings, e.g. 2023/01/01 and 2023/01/31. The end date must be
later than the start date. Start date must be less than or equal to today, and end date must be greater than
or equal to today. Alternatively, these dates can be left blank to set them as nil (must both be present or both blank).
Cost cannot be blank.

```
./update-user-cost.sh <USER_ID> <COST> <BILLING_PERIOD_START> <BILLING_PERIOD_END>
```

Delete a user.  If recurse is given, any racks and devices belonging to the
user are deleted.  If recurse is not given this will fail if the user has any
racks or devices.  It is not currently permitted to delete any admin users.

```
./delete-user.sh <USER_ID> [recurse]
```

### Racks

List all racks.

```
./list-racks.sh
```

Create a new rack.  If `RACK_NAME` or `U_HEIGHT` are not provided defaults
based on the previous rack will be created.

```
./create-rack.sh <ORDER_ID> [<USER_ID> [RACK_NAME [U_HEIGHT]]]
```

Show a rack including its nodes.

```
./show-rack.sh <RACK_ID>
```

Update a rack's name and height.

```
./update-rack.sh <RACK_ID> <NAME> <HEIGHT>
```

Update a rack's cost for the current billing period.

```
./update-rack-cost.sh <RACK_ID> <COST>
```

Delete a rack.  If recurse is given, any nodes in the rack are deleted.  If
recurse is not given this will fail on non-empty racks.

```
./delete-rack.sh <RACK_ID> [recurse]
```

### Templates

List all available device templates.

```
./list-templates.sh
```

Create a template.  A suitable image for the template will be selected based on
the provided height.  Currently, there is no option to provide a custom image.

```
./create-template.sh <NAME> <DESCRIPTION> <U_HEIGHT>
```

Update a template's name and description.  The template's height cannot be
updated so as to avoid an issue where this could result in overlapping devices
in a rack.

```
./update-template.sh <TEMPLATE_ID> <NAME> <DESCRIPTION>
```

Delete a template.  If recurse is given, any devices created from the template
will be deleted.  If recurse is not given this will fail if any devices have
been created from the template.

```
./delete-template.sh <TEMPLATE_ID> [recurse]
```

### Devices

List all devices.

```
./list-devices.sh
```

Create a device.  The rack id and template id can be obtained from the
`list-racks.sh` and `list-template.sh` example scripts.  Valid values for
facing are `f` or `b` for front and back respectively.

```
./create-device.sh <NAME> <RACK_ID> <FACING> <START_U> <TEMPLATE_ID>
```

Move a device.

```
./move-device.sh <DEVICE_ID> <FACING> <START_U>
```

Update a device's name.

```
./update-device.sh <DEVICE_ID> <NAME>
```

Update a device's status.  Both the simple and detailed status are updated.

```
./update-device-status.sh <DEVICE_ID> <SIMPLE_STATUS> <DETAILED_STATUS>
```

Update a device's cost for the current billing period.

```
./update-device-cost.sh <DEVICE_ID> <SIMPLE_STATUS> <DETAILED_STATUS>
```

Delete a device.

```
./delete-device.sh <DEVICE_ID>
```
