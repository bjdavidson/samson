# frozen_string_literal: true
module SamsonGcloud
  class ImageScanner
    class << self
      def scan(build)
        url = build.docker_repo_digest
        url = "https://#{url}" unless url.start_with?("http")

        response = Faraday.get(
          "https://containeranalysis.googleapis.com/v1alpha1/projects/#{SamsonGcloud.project}/occurrences",
          {
            filter: "resourceUrl=\"#{url}\"",
            pageSize: 1
          },
          authorization: "Bearer #{token}"
        )
        raise "Unable to fetch vulnerabilities: #{response.status} -- #{response.body}" unless response.status == 200
        JSON.load(response.body).empty?
      end

      def result_url(build)
        digest_base = build.docker_repo_digest.split(SamsonGcloud.project).last
        "https://console.cloud.google.com/gcr/images/#{SamsonGcloud.project}/GLOBAL/#{digest_base}/details/vulnz"
      end

      private

      # TODO: cache token for 29 mins
      def token
        success, result = Samson::CommandExecutor.execute(
          "gcloud", "auth", "print-access-token", *SamsonGcloud.cli_options,
          timeout: 5,
          whitelist_env: ["PATH"]
        )
        raise "GCLOUD ERROR: #{success}" unless success
        result
      end
    end
  end
end
