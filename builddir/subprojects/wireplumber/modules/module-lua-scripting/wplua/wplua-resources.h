#ifndef __RESOURCE__wplua_H__
#define __RESOURCE__wplua_H__

#include <gio/gio.h>

G_GNUC_INTERNAL GResource *_wplua_get_resource (void);

G_GNUC_INTERNAL void _wplua_register_resource (void);
G_GNUC_INTERNAL void _wplua_unregister_resource (void);

#endif
