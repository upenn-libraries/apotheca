# frozen_string_literal: true

# A tool for listing file on a specified attached drive at a specified path
class FileListingToolController < ApplicationController
  def tool; end

  def file_list
    respond_to do |format|
      if valid_drive? && valid_path?
        if filenames.present?
          format.csv { send_data csv, type: 'text/csv', filename: 'structural_metadata.csv', disposition: :download }
          format.json { render json: { filenames: filenames.join('; '), drive: params[:drive], path: params[:path] }, status: :ok }
        else
          format.csv {}
          format.json { render json: { drive: params[:drive], path: params[:path] }, status: :unprocessable_entity }
        end
      else
        format.csv {}
        format.json { render json: { error: 'Path invalid!' }, status: :unprocessable_entity }
      end
    end
  end

  private

  def csv
    data = filenames.map { |f| { filename: f } }
    StructuredCSV.generate(data)
  end

  def valid_path?
    storage.valid_path?(params[:path]) if valid_drive?
  end

  def valid_drive?
    ImportService::S3Storage.valid?(params[:drive])
  end

  def filenames
    storage.files_at(params[:path]).map { |file| File.basename(file) }
  end

  def storage
    @storage ||= ImportService::S3Storage.new(params[:drive]) if valid_drive?
  end
end
