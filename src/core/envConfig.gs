function getEnv(key) {
  const env = PropertiesService.getScriptProperties().getProperty(key);
  if (!env) throw new Error(`Missing env: ${key}`);
  return env;
}
