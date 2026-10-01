/// Claves de `sync_state` que son del teléfono y no de la sesión: cerrar
/// sesión (o entrar con otro usuario) no las borra. Llevan el id del
/// usuario cuando son por usuario (`device:onboarding_done:<userId>`), así
/// que otra persona en el mismo teléfono no hereda las de nadie. Borrar la
/// cuenta sí las quita (P6).
const deviceStatePrefix = 'device:';

String deviceStateKey(String key) => '$deviceStatePrefix$key';

bool isDeviceStateKey(String key) => key.startsWith(deviceStatePrefix);
