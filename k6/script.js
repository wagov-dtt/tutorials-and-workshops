import http from 'k6/http';
export const options = {
  vus: 100,
  duration: '15s',
};
export default function () {
    http.get(`https://${__ENV.TARGET}/`);
}