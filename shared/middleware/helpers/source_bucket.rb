require 'cdo/project_source_json'
#
# SourceBucket
#
class SourceBucket < BucketHelper
  def initialize
    super CDO.sources_s3_bucket, CDO.sources_s3_directory
  end

  def allowed_file_types
    # Only allow JavaScript and Blockly XML source files.
    %w(.js .xml .txt .json)
  end

  def cache_duration_seconds
    0
  end

  # Copies the given version of the file to make it the current revision.
  # (All intermediate versions are preserved.)
  # Copies the animations at the given version and makes them the current version.
  def restore_previous_version(encrypted_channel_id, filename, version_id, user_id)
    owner_id, channel_id = storage_decrypt_channel_id(encrypted_channel_id)
    key = s3_path owner_id, channel_id, filename

    response = s3.get_object(bucket: @bucket, key: key, version_id: version_id)
    response = response.body.read

    psj = ProjectSourceJson.new(response)

    if psj.animation_manifest?
      # Make copies of each animation at the specified version
      # Update the manifest to reference the copied animations
      anim_bucket = AnimationBucket.new
      psj.each_animation do |a|
        anim_response = anim_bucket.restore_previous_version(encrypted_channel_id, a.key, a.version_id, a.user_id)
        psj.set_animation_version(a.key, anim_response.version_id)
      end

      # Put the manifest with the updated animations in S3
      response = s3.put_object(bucket: @bucket, key: key, body: psj.to_s)
    end


    # If we get this far, the restore request has succeeded.
    FirehoseClient.instance.put_record(
      study: 'project-data-integrity',
      study_group: 'v2',
      event: 'version-restored',

      # Make it easy to limit our search to restores in the sources bucket for a certain project.
      project_id: encrypted_channel_id,
      data_string: @bucket,

      user_id: user_id,
      data_json: {
        restoredVersionId: version_id,
        newVersionId: response.version_id,
        bucket: @bucket,
        key: key,
        filename: filename,
      }.to_json
    )

    response
  end
end
