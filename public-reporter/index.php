<?php

use GuzzleHttp\Promise\Utils;

require_once("../vendor/autoload.php");

$dotenv = Dotenv\Dotenv::createImmutable(__DIR__ . "/../");
$dotenv->safeLoad();

$targets = explode(",", $_ENV['TARGETS']);
# trim whitespace from each target
$targets = array_map('trim', $targets);

# For each $target, resolve the target to IP addresses
foreach($targets as $target) {
    $targetIps[$target] = gethostbynamel($target) ?: [];
    $targetIps[$target] = array_values($targetIps[$target]);
}
# For each $target, Create a guzzle request to get the status of each target
$guzzle = new GuzzleHttp\Client();
$promises = [];
foreach ($targets as $target) {
    $url = "http://$target:80/";
    $promises[$target] = $guzzle->getAsync($url);
}
# Wait for all the requests to complete
$responses = Utils::settle($promises)->wait();
$rollup = true;
$json = [];
foreach($responses as $target => $response) {
    if(!isset($response['value']) || $response['value']->getStatusCode() != 200) {
        $rollup = false;
        if ($response['reason'] instanceof \Exception) {
            $json[$target] = ['Status' => 'ERROR', 'Reason' => $response['reason']->getMessage()];
        } else {
            $json[$target] = ['Status' => "ERROR", 'Reason' => 'Unknown'];
        }
    } else {
        $json[$target] = json_decode($response['value']->getBody()->getContents(), true);
    }
    $json[$target]['IP'] = $targetIps[$target];

}
if(!$rollup) {
    header("HTTP/1.0 500 Internal Server Error");
}
header('Content-Type: application/json; charset=utf-8');
echo json_encode([
    'Status' => $rollup ? "OK" : "ERROR",
    'Hostname' => gethostname(),
    'Targets' => $json,
]);
