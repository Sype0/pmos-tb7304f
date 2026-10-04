/*
 * Android system properties and logging for the two WMT programs of the
 * stock firmware (wmt_loader, wmt_launcher) when they run outside Android.
 *
 * There is no property service here, and wmt_launcher waits for a property
 * that wmt_loader sets before it configures the driver. This library is
 * preloaded into both: properties are files in /run/tb7304f-props, and the
 * log goes to stderr.
 *
 * Built for bionic (the programs run on the C library of the stock
 * firmware): clang -shared -fPIC -O2 -o libtb7304f-props.so props.c
 */
#include <fcntl.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#define PROPS_DIR "/run/tb7304f-props"
#define PROPERTY_VALUE_MAX 92

static void prop_path(char *path, size_t size, const char *key)
{
	snprintf(path, size, PROPS_DIR "/%s", key);
}

int property_get(const char *key, char *value, const char *default_value)
{
	char path[256];
	int fd;
	ssize_t len = -1;

	prop_path(path, sizeof(path), key);
	fd = open(path, O_RDONLY | O_CLOEXEC);
	if (fd >= 0) {
		len = read(fd, value, PROPERTY_VALUE_MAX - 1);
		close(fd);
	}
	if (len > 0) {
		while (len > 0 && value[len - 1] == '\n')
			len--;
		value[len] = '\0';
		return (int)len;
	}

	if (default_value) {
		len = (ssize_t)strlen(default_value);
		if (len >= PROPERTY_VALUE_MAX)
			len = PROPERTY_VALUE_MAX - 1;
		memcpy(value, default_value, (size_t)len);
		value[len] = '\0';
		return (int)len;
	}
	value[0] = '\0';
	return 0;
}

int property_set(const char *key, const char *value)
{
	char path[256];
	int fd;
	size_t len = strlen(value);

	mkdir(PROPS_DIR, 0755);
	prop_path(path, sizeof(path), key);
	fd = open(path, O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0644);
	if (fd < 0)
		return -1;
	if (write(fd, value, len) != (ssize_t)len) {
		close(fd);
		return -1;
	}
	close(fd);
	return 0;
}

int __android_log_print(int prio, const char *tag, const char *fmt, ...)
{
	va_list ap;

	fprintf(stderr, "%s(%d): ", tag ? tag : "", prio);
	va_start(ap, fmt);
	vfprintf(stderr, fmt, ap);
	va_end(ap);
	fputc('\n', stderr);
	return 0;
}
